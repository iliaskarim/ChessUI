import ChessCore
import SwiftUI

// MARK: -
private extension Piece {
  var image: Image {
    switch (color, figure) {
    case (.black, .bishop):
      .init("BlackBishop", bundle: .module)

    case (.black, .king):
      .init("BlackKing", bundle: .module)

    case (.black, .knight):
      .init("BlackKnight", bundle: .module)

    case (.black, .pawn):
      .init("BlackPawn", bundle: .module)

    case (.black, .queen):
      .init("BlackQueen", bundle: .module)

    case (.black, .rook):
      .init("BlackRook", bundle: .module)

    case (.white, .bishop):
      .init("WhiteBishop", bundle: .module)

    case (.white, .king):
      .init("WhiteKing", bundle: .module)

    case (.white, .knight):
      .init("WhiteKnight", bundle: .module)

    case (.white, .pawn):
      .init("WhitePawn", bundle: .module)

    case (.white, .queen):
      .init("WhiteQueen", bundle: .module)

    case (.white, .rook):
      .init("WhiteRook", bundle: .module)
    }
  }
}

// MARK: -
private extension [Play] {
  func promotion(figure: Piece.Figure) -> Play? {
    first { play in
      if case let .translation(translation) = play, translation.promotion == figure {
        true
      } else {
        false
      }
    }
  }
}

// MARK: -
extension View {
  func labelTextStyle() -> some View {
    modifier(ChessBoard.LabelTextModifier())
  }
}

// MARK: - ChessBoard
struct ChessBoard: View {
  fileprivate struct LabelTextModifier: ViewModifier {
    func body(content: Content) -> some View {
      content
        .monospaced()
        .font(.system(size: 13.0))
    }
  }

  @ObservedObject private var game: Game

  @Binding private var isBoardFlipped: Bool

  @Binding private var isBoardLabeled: Bool

  @State private var promotions: [Play]?

  @State private var plays: [Square: [Play]]?

  private let scale = 30.0

  @State private var showPromotionDialog = false

  @State private var selection: Square? {
    didSet {
      plays = switch selection {
      case let .some(square):
        game.board.plays(from: square)

      case .none:
        [:]
      }
    }
  }

  @State private var showForfeitureConfirmation = false

  var body: some View {
    HStack(spacing: 0) {
      // Rank labels
      if isBoardLabeled {
        VStack(alignment: .trailing, spacing: 0) {
          ForEach(isBoardFlipped ? Square.Rank.allCases : Square.Rank.allCases.reversed(), id: \.rawValue) { file in
            Text(verbatim: file.description)
              .labelTextStyle()
              .frame(height: scale)
          }
          Spacer()
        }
        .frame(width: 10.0, height: scale * 8 + 20.0)
        .padding(.trailing, 10.0)
      }

      VStack(spacing: 0) {
        // Board grid
        ForEach(0 ..< 8) { i in
          HStack(spacing: 0) {
            ForEach(0 ..< 8) { j in
              square(i: i, j: j)
            }
          }
        }

        // File labels
        if isBoardLabeled {
          HStack(spacing: 0) {
            ForEach(isBoardFlipped ? Square.File.allCases.reversed() : Square.File.allCases, id: \.rawValue) { file in
              Text(verbatim: file.description)
                .labelTextStyle()
                .frame(width: scale)
            }
          }
          .frame(height: 10.0)
          .padding(.top, 10.0)
        }
      }
    }
    .confirmationDialog("Promotion", isPresented: $showPromotionDialog) {
      Button("Promote pawn to queen") {
        try! game.play(promotions!.promotion(figure: .queen)!)
      }
      Button("Promote pawn to bishop") {
        try! game.play(promotions!.promotion(figure: .bishop)!)
      }
      Button("Promote pawn to knight") {
        try! game.play(promotions!.promotion(figure: .knight)!)
      }
      Button("Promote pawn to rook") {
        try! game.play(promotions!.promotion(figure: .rook)!)
      }
    }
  }

  init(game: Game, isBoardFlipped: Binding<Bool>, isBoardLabeled: Binding<Bool>) {
    self.game = game
    _isBoardFlipped = isBoardFlipped
    _isBoardLabeled = isBoardLabeled
  }

  private func square(i: Int, j: Int) -> some View {
    let file: Square.File = isBoardFlipped ? .allCases[7 - j] : .allCases[j]
    let rank: Square.Rank = isBoardFlipped ? .allCases[i] : .allCases[7 - i]
    let square = Square(file: file, rank: rank)
    let piece = game.board[square]

    return Color((i + j) % 2 == 0 ? .white : Color(white: 0.81))
      .frame(width: scale, height: scale)
      .overlay {
        piece?.image.resizable()
      }
      .modifier(PressAction {
        guard case let .toMove(toMove) = game.status else {
          return
        }

        if let piece, piece.color == toMove {
          selection = square
        } else if let plays = plays?[square] {
          if plays.count > 1 {
            promotions = plays
            showPromotionDialog = true
          } else {
            try! game.play(plays.first!)
          }
          selection = nil
        } else {
          selection = nil
        }
      })
      .overlay {
        if let plays, plays.keys.contains(square) {
          if piece != nil {
            Rectangle()
              .stroke(.black, lineWidth: 1.0)
              .foregroundStyle(.clear)
              .padding(1.0)
          } else {
            Circle().frame(width: 3.0)
          }
        }
      }
  }
}

struct ChessBoard_Previews: PreviewProvider {
  @State private static var isBoardFlipped = false
  @State private static var isBoardLabeled = true

  static var previews: some View {
    ChessBoard(game: .init(), isBoardFlipped: $isBoardFlipped, isBoardLabeled: $isBoardLabeled)
  }
}
