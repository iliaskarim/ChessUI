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
        promote(to: .queen)
      }
      .accessibilityIdentifier("promotion-queen")
      Button("Promote pawn to bishop") {
        promote(to: .bishop)
      }
      .accessibilityIdentifier("promotion-bishop")
      Button("Promote pawn to knight") {
        promote(to: .knight)
      }
      .accessibilityIdentifier("promotion-knight")
      Button("Promote pawn to rook") {
        promote(to: .rook)
      }
      .accessibilityIdentifier("promotion-rook")
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
    .onChange(of: isBoardFlipped) {
      guard gesture != nil else {
        return
      }

      // The pointer's square changed with the flip. Drop the gesture.
      gesture = nil
      ignoreGesture = true
    }
    .onChange(of: showPromotionDialog) {
      guard !showPromotionDialog else {
        return
      }

      defer {
        promotionWasChosen = false
      }

      guard pendingPromotionSquare != nil, !promotionWasChosen else {
        return
      }

      withAnimation(.easeOut(duration: 0.15)) {
        pendingPromotionSquare = nil
      }
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

  private let dragThreshold = 6.0

  private let dragOriginOpacity = 0.35

  @State private var gesture: BoardPress?

  @State private var ignoreGesture = false

  @State private var pendingPromotionSquare: Square?

  @State private var promotionWasChosen = false

  @State private var showPromotionDialog = false

  @State private var selection: Square?

  private var isDraggingPiece: Bool {
    gesture?.isDragging == true
  }

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

  private func promote(to figure: Piece.Figure) {
    promotionWasChosen = true
    pendingPromotionSquare = nil
    play(promotions!.promotion(figure: figure)!, isCapture: isPromotionCapture)
  }

  private func deselect() {
    selection = nil
    guard gesture != nil else {
      return
    }

    gesture = nil
    ignoreGesture = true
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
    .contentShape(Rectangle())
    .gesture(boardDrag)
#if os(macOS)
      .modifier(
        BoardCrosshairCursorModifier(
          isPieceSelected: selection != nil,
          isDragging: isDraggingPiece
        )
      )
#endif
  }

  private var boardDrag: some Gesture {
    DragGesture(minimumDistance: 0, coordinateSpace: .local)
      .onChanged { value in
        dragChanged(value)
      }
      .onEnded { value in
        dragEnded(value)
      }
  }

  @ViewBuilder private var liftedPiece: some View {
    if let selection, let piece = game.board[selection] {
      let pieceScale = pendingPromotionSquare == nil ? selectedPieceScale : 1
      let side = scale * pieceScale
      piece.image
        .resizable()
        .frame(width: side, height: side)
        .shadow(color: .black.opacity(0.45), radius: 1.5, y: 1)
        .offset(liftedPieceOffset(side: side))
        .transaction { transaction in
          if isDraggingPiece {
            transaction.animation = nil
          }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
  }

  private func liftedPieceOffset(side: CGFloat) -> CGSize {
    let center = liftedPieceCenter()
    return CGSize(width: center.x - side / 2, height: center.y - side / 2)
  }

  private func liftedPieceCenter() -> CGPoint {
    if let pendingPromotionSquare {
      return squareCenter(pendingPromotionSquare)
    }
    if let gesture, gesture.isDragging {
      return CGPoint(
        x: gesture.location.x - gesture.grabOffset.width,
        y: gesture.location.y - gesture.grabOffset.height
      )
    }
    if let selection {
      return squareCenter(selection)
    }
    return .zero
  }

  private func squareCenter(_ square: Square) -> CGPoint {
    boardSquareCenter(square, scale: scale, isFlipped: isBoardFlipped)
  }

  private func square(at location: CGPoint) -> Square? {
    boardSquare(at: location, scale: scale, isFlipped: isBoardFlipped)
  }

  private func dragChanged(_ value: DragGesture.Value) {
    guard !showPromotionDialog, !ignoreGesture else {
      return
    }

    if gesture == nil {
      gesture = beginPress(at: value.startLocation)
    }

    guard var press = gesture, !press.handled else {
      return
    }

    let traveled = hypot(value.translation.width, value.translation.height)
    guard press.isDragging || traveled >= dragThreshold else {
      return
    }

    press.location = value.location
    press.isDragging = true
    press.defersDeselect = false
    gesture = press
  }

  private func dragEnded(_ value: DragGesture.Value) {
    defer {
      ignoreGesture = false
    }

    guard !ignoreGesture, let press = gesture, !press.handled, !showPromotionDialog else {
      gesture = nil
      return
    }

    if press.isDragging {
      var press = press
      press.location = value.location
      finishDrag(press)
      return
    }

    if press.defersDeselect {
      deselect()
      return
    }

    gesture = nil
  }

  private func beginPress(at point: CGPoint) -> BoardPress {
    guard let square = square(at: point) else {
      return BoardPress(origin: nil, location: point, grabOffset: .zero, handled: true)
    }

    let result = press(square, deferToggle: true)
    let center = squareCenter(square)
    return BoardPress(
      origin: square,
      location: point,
      grabOffset: CGSize(width: point.x - center.x, height: point.y - center.y),
      defersDeselect: result == .deferDeselect,
      handled: result == .handled
    )
  }

  /// `deferToggle` keeps a second press on the selected piece selected until
  /// release, so that press can become a drag.
  @discardableResult
  private func press(_ square: Square, deferToggle: Bool) -> PiecePress {
    guard case let .toMove(toMove) = game.status else {
      return .handled
    }

    if let piece = game.board[square], piece.color == toMove, !game.board.moves(from: square).isEmpty {
      if selection == square {
        if deferToggle {
          return .deferDeselect
        }
        deselect()
        return .handled
      }

      selection = square
      return .selected
    }

    if let moves = activePlays[square] {
      chooseDestination(square, moves: moves, fromDrag: false)
      return .handled
    }

    deselect()
    SoundManager.shared.playButtonPressShort()
    return .handled
  }

  private func finishDrag(_ press: BoardPress) {
    // The piece is the pointer, so the drop square is the one under its center.
    let center = CGPoint(
      x: press.location.x - press.grabOffset.width,
      y: press.location.y - press.grabOffset.height
    )
    let target = square(at: center)
    guard let target, let moves = activePlays[target], !moves.isEmpty else {
      withAnimation(.easeOut(duration: 0.15)) {
        gesture = nil
      }
      return
    }

    gesture = nil
    chooseDestination(target, moves: moves, fromDrag: true)
  }

  private func chooseDestination(_ square: Square, moves: [Move], fromDrag: Bool) {
    if moves.count > 1 {
      promotions = moves
      isPromotionCapture = game.board[square] != nil
      promotionWasChosen = false
      if fromDrag {
        pendingPromotionSquare = square
      }
      showPromotionDialog = true
    } else {
      play(moves.first!, isCapture: game.board[square] != nil)
    }
  }

  private func square(i: Int, j: Int, plays: [Square: [Move]]) -> some View {
    let file: Square.File = isBoardFlipped ? .allCases[7 - j] : .allCases[j]
    let rank: Square.Rank = isBoardFlipped ? .allCases[i] : .allCases[7 - i]
    let square = Square(file: file, rank: rank)
    let piece = game.board[square]
    let isSelected = selection == square
    let showsDragOrigin = isSelected && (isDraggingPiece || pendingPromotionSquare != nil)

    return Color((i + j) % 2 == 0 ? .white : Color(white: 0.81))
      .frame(width: scale, height: scale)
      .overlay {
        if showsDragOrigin {
          piece?.image
            .resizable()
            .opacity(dragOriginOpacity)
        } else if !isSelected {
          piece?.image.resizable()
        }
      }
      .accessibilityElement()
      .accessibilityIdentifier(square.description)
      .accessibilityLabel(square.description)
      .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
      .accessibilityAction {
        press(square, deferToggle: false)
      }
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
/// Crosshair over the squares while a piece is selected. Hidden while dragging,
/// because the piece follows the pointer. Labels keep the arrow.
private struct BoardCrosshairCursorModifier: ViewModifier {
  var isPieceSelected: Bool

  var isDragging: Bool

  @State private var isCrosshairPushed = false

  @State private var isPointerOverBoard = false

  @State private var isCursorHidden = false

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
      .onChange(of: isDragging) {
        updateCursor()
      }
      .onDisappear {
        isPointerOverBoard = false
        restoreCursor()
      }
  }

  private func updateCursor() {
    if isDragging {
      if isCrosshairPushed {
        NSCursor.pop()
        isCrosshairPushed = false
      }
      if !isCursorHidden {
        NSCursor.hide()
        isCursorHidden = true
      }
      return
    }

    if isCursorHidden {
      NSCursor.unhide()
      isCursorHidden = false
    }

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

  private func restoreCursor() {
    if isCursorHidden {
      NSCursor.unhide()
      isCursorHidden = false
    }
    if isCrosshairPushed {
      NSCursor.pop()
      isCrosshairPushed = false
    }
  }
}
#endif

private struct BoardPress {
  var origin: Square?

  var location: CGPoint

  var grabOffset: CGSize

  var defersDeselect = false

  var isDragging = false

  var handled = false
}

private enum PiecePress {
  case selected

  case deferDeselect

  case handled
}

func boardSquareCenter(_ square: Square, scale: CGFloat, isFlipped: Bool) -> CGPoint {
  let fileIndex = square.file.rawValue - 1
  let rankIndex = square.rank.rawValue - 1
  let column = isFlipped ? 7 - fileIndex : fileIndex
  let row = isFlipped ? rankIndex : 7 - rankIndex
  return CGPoint(
    x: (CGFloat(column) + 0.5) * scale,
    y: (CGFloat(row) + 0.5) * scale
  )
}

func boardSquare(at location: CGPoint, scale: CGFloat, isFlipped: Bool) -> Square? {
  let side = scale * 8
  guard location.x >= 0, location.y >= 0, location.x < side, location.y < side else {
    return nil
  }

  let column = min(Int(location.x / scale), 7)
  let row = min(Int(location.y / scale), 7)
  let fileIndex = isFlipped ? 7 - column : column
  let rankIndex = isFlipped ? row : 7 - row
  guard let file = Square.File(rawValue: fileIndex + 1),
        let rank = Square.Rank(rawValue: rankIndex + 1) else {
    return nil
  }

  return Square(file: file, rank: rank)
}

#Preview {
  @State var isBoardFlipped = false

  @State var isBoardLabeled = true

  ChessBoard(
    game: .init(),
    isBoardFlipped: $isBoardFlipped,
    isBoardLabeled: $isBoardLabeled
  )
}
