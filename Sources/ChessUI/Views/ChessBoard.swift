import ChessCore
import SwiftUI
#if os(macOS)
import AppKit
#endif

struct ChessBoard: View {
  var body: some View {
    let plays = activePlays

    HStack(spacing: 0) {
      // RANK LABELS
      if isBoardLabeled {
        rankLabels
      }

      VStack(spacing: 0) {
        boardGrid(plays: plays)

        // FILE LABELS
        if isBoardLabeled {
          fileLabels
        }
      }
    }
    .confirmationDialog("Promotion", isPresented: $showPromotionDialog) {
      Button("Promote pawn to queen") {
        play(promotions!.promotion(figure: .queen)!, isCapture: isPromotionCapture)
      }
      Button("Promote pawn to bishop") {
        play(promotions!.promotion(figure: .bishop)!, isCapture: isPromotionCapture)
      }
      Button("Promote pawn to knight") {
        play(promotions!.promotion(figure: .knight)!, isCapture: isPromotionCapture)
      }
      Button("Promote pawn to rook") {
        play(promotions!.promotion(figure: .rook)!, isCapture: isPromotionCapture)
      }
    }
#if os(macOS)
    .background {
      // A click does not focus the board, so Escape is a shortcut rather than a key press.
      Button {
        guard selection != nil, !showPromotionDialog else {
          return
        }

        deselect()
      } label: {
        EmptyView()
      }
      .keyboardShortcut(.cancelAction)
      .disabled(selection == nil || showPromotionDialog)
      .buttonStyle(.plain)
      .opacity(0)
      .allowsHitTesting(false)
      .accessibilityHidden(true)
    }
#endif
    .onChange(of: chessBoardDeselectCount) {
      guard selection != nil, !showPromotionDialog else {
        return
      }

      deselect()
    }
  }

  private var fileLabels: some View {
    HStack(spacing: 0) {
      ForEach(
        isBoardFlipped ? Square.File.allCases.reversed() : Square.File.allCases,
        id: \.rawValue
      ) { file in
        Text(verbatim: file.description)
          .labelTextStyle()
          .frame(width: scale)
      }
    }
    .frame(height: 10.0)
    .padding(.top, 10.0)
  }

  @ObservedObject private var game: Game

  @Binding private var isBoardFlipped: Bool

  @Binding private var isBoardLabeled: Bool

  @Environment(\.chessBoardDeselectCount)
  private var chessBoardDeselectCount

  @State private var isPromotionCapture = false

  @State private var promotions: [Move]?

  private var rankLabels: some View {
    VStack(alignment: .trailing, spacing: 0) {
      ForEach(
        isBoardFlipped ? Square.Rank.allCases : Square.Rank.allCases.reversed(),
        id: \.rawValue
      ) { rank in
        Text(verbatim: rank.description)
          .labelTextStyle()
          .frame(height: scale)
      }
      Spacer()
    }
    .frame(width: 10.0, height: scale * 8 + 20.0)
    .padding(.trailing, 10.0)
  }

  private let scale = 30.0

  private let selectedPieceScale = 1.1

  @State private var showPromotionDialog = false

  @State private var selection: Square?

  private var activePlays: [Square: [Move]] {
    switch selection {
    case let .some(square):
      game.board.moves(from: square)

    case .none:
      [:]
    }
  }

  init(game: Game, isBoardFlipped: Binding<Bool>, isBoardLabeled: Binding<Bool>) {
    self.game = game
    _isBoardFlipped = isBoardFlipped
    _isBoardLabeled = isBoardLabeled
  }

  private func play(_ move: Move, isCapture: Bool) {
    try! game.play(move)
    SoundManager.shared.playMove(
      move,
      status: game.status,
      boardStatus: game.board.status,
      isCapture: isCapture
    )
    selection = nil
  }

  private func deselect() {
    selection = nil
  }

  private func boardGrid(plays: [Square: [Move]]) -> some View {
    VStack(spacing: 0) {
      ForEach(0 ..< 8) { i in
        HStack(spacing: 0) {
          ForEach(0 ..< 8) { j in
            square(i: i, j: j, plays: plays)
          }
        }
      }
    }
    // Drawn above the squares so the lift isn't covered by a neighboring square.
    .overlay(alignment: .topLeading) {
      liftedPiece
    }
#if os(macOS)
    .modifier(BoardCrosshairCursorModifier(isPieceSelected: selection != nil))
#endif
  }

  @ViewBuilder private var liftedPiece: some View {
    if let selection, let piece = game.board[selection] {
      let side = scale * selectedPieceScale
      piece.image
        .resizable()
        .frame(width: side, height: side)
        .shadow(color: .black.opacity(0.45), radius: 1.5, y: 1)
        .offset(liftedPieceOffset(for: selection, side: side))
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }

  private func liftedPieceOffset(for square: Square, side: CGFloat) -> CGSize {
    let center = squareCenter(square)
    return CGSize(width: center.x - side / 2, height: center.y - side / 2)
  }

  private func squareCenter(_ square: Square) -> CGPoint {
    let fileIndex = square.file.rawValue - 1
    let rankIndex = square.rank.rawValue - 1
    let column = isBoardFlipped ? 7 - fileIndex : fileIndex
    let row = isBoardFlipped ? rankIndex : 7 - rankIndex
    return CGPoint(
      x: (CGFloat(column) + 0.5) * scale,
      y: (CGFloat(row) + 0.5) * scale
    )
  }

  private func square(i: Int, j: Int, plays: [Square: [Move]]) -> some View {
    let file: Square.File = isBoardFlipped ? .allCases[7 - j] : .allCases[j]
    let rank: Square.Rank = isBoardFlipped ? .allCases[i] : .allCases[7 - i]
    let square = Square(file: file, rank: rank)
    let piece = game.board[square]

    let press = {
      guard case let .toMove(toMove) = game.status else {
        return
      }

      if let piece, piece.color == toMove, !game.board.moves(from: square).isEmpty {
        if selection == square {
          deselect()
        } else {
          selection = square
        }
      } else if let plays = plays[square] {
        if plays.count > 1 {
          promotions = plays
          isPromotionCapture = piece != nil
          showPromotionDialog = true
        } else {
          play(plays.first!, isCapture: piece != nil)
        }
      } else {
        deselect()
        SoundManager.shared.playButtonPressShort()
      }
    }

    let isSelected = selection == square

    return Color((i + j) % 2 == 0 ? .white : Color(white: 0.81))
      .frame(width: scale, height: scale)
      .overlay {
        if !isSelected {
          piece?.image.resizable()
        }
      }
      .modifier(PressAction(onPress: press))
      .accessibilityElement()
      .accessibilityIdentifier(square.description)
      .accessibilityLabel(square.description)
      .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
      .accessibilityAction { press() }
      .overlay {
        if plays.keys.contains(square) {
          if piece != nil {
            Rectangle()
              .stroke(.black, lineWidth: 1.0)
              .foregroundStyle(.clear)
              .padding(1.0)
          } else {
            Circle()
              .fill(.black)
              .frame(width: 2.0)
          }
        }
      }
  }
}

#if os(macOS)
/// Crosshair over the squares while a piece is selected. Labels keep the arrow.
private struct BoardCrosshairCursorModifier: ViewModifier {
  var isPieceSelected: Bool

  @State private var isCrosshairPushed = false

  @State private var isPointerOverBoard = false

  func body(content: Content) -> some View {
    content
      .onContinuousHover { phase in
        switch phase {
        case .active:
          isPointerOverBoard = true
          updateCursor()

        case .ended:
          isPointerOverBoard = false
          updateCursor()
        }
      }
      .onChange(of: isPieceSelected) {
        updateCursor()
      }
      .onDisappear {
        isPointerOverBoard = false
        updateCursor()
      }
  }

  private func updateCursor() {
    let showCrosshair = isPieceSelected && isPointerOverBoard
    if showCrosshair {
      if !isCrosshairPushed {
        NSCursor.crosshair.push()
        isCrosshairPushed = true
      } else if NSCursor.current != NSCursor.crosshair {
        // A cursor rect replaces a pushed cursor without popping it.
        // set() restores the crosshair. A second push would stick after pop().
        NSCursor.crosshair.set()
      }
    } else if isCrosshairPushed {
      NSCursor.pop()
      isCrosshairPushed = false
    }
  }
}
#endif

#Preview {
  @State var isBoardFlipped = false

  @State var isBoardLabeled = true

  ChessBoard(
    game: .init(),
    isBoardFlipped: $isBoardFlipped,
    isBoardLabeled: $isBoardLabeled
  )
}
