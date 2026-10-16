import ChessCore

/// Sam Loyd's ten-move stalemate. White's last move is Qe6.
enum LoydStalemate {
  static let moves: [Move] = [
    pawn(.e, .three),
    pawn(.a, .five),
    queen(.h, .five),
    rook(.a, .six),
    queen(.a, .five, capture: true),
    pawn(.h, .five),
    pawn(.h, .four),
    rook(.h, .six, file: .a),
    queen(.c, .seven, capture: true),
    pawn(.f, .six),
    queen(.d, .seven, capture: true),
    king(.f, .seven),
    queen(.b, .seven, capture: true),
    queen(.d, .three),
    queen(.b, .eight, capture: true),
    queen(.h, .seven),
    queen(.c, .eight, capture: true),
    king(.g, .six),
    queen(.e, .six)
  ]

  private static func pawn(_ file: Square.File, _ rank: Square.Rank) -> Move {
    .translation(.init(figure: .pawn, targetSquare: .init(file: file, rank: rank)))
  }

  private static func queen(_ file: Square.File, _ rank: Square.Rank, capture: Bool = false) -> Move {
    .translation(.init(
      figure: .queen,
      targetSquare: .init(file: file, rank: rank),
      isCapture: capture
    ))
  }

  private static func rook(
    _ file: Square.File,
    _ rank: Square.Rank,
    file disambiguation: Square.File? = nil
  ) -> Move {
    .translation(.init(
      figure: .rook,
      targetSquare: .init(file: file, rank: rank),
      disambiguationFile: disambiguation
    ))
  }

  private static func king(_ file: Square.File, _ rank: Square.Rank) -> Move {
    .translation(.init(figure: .king, targetSquare: .init(file: file, rank: rank)))
  }
}
