import ChessCore
import SwiftUI

extension Piece {
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
