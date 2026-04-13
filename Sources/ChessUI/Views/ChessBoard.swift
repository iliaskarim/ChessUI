import ChessCore
import SwiftUI

struct ChessBoard: View {
  var body: some View {
    HStack(spacing: 0) {
      // RANK LABELS
      if isBoardLabeled {
        rankLabels
      }

      VStack(spacing: 0) {
        // BOARD GRID
        ForEach(0 ..< 8) { i in
          HStack(spacing: 0) {
            ForEach(0 ..< 8) { j in
              square(i: i, j: j)
            }
          }
        }

        // FILE LABELS
        if isBoardLabeled {
          fileLabels
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

  @State private var promotions: [Move]?

  @State private var plays: [Square: [Move]]?

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

  @State private var showPromotionDialog = false

  @State private var selection: Square? {
    didSet {
      plays = switch selection {
      case let .some(square):
        game.board.moves(from: square)

      case .none:
        [:]
      }
    }
  }

  @State private var showForfeitureConfirmation = false

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
            Circle()
              .fill(.black)
              .frame(width: 3.0)
          }
        }
      }
  }
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
