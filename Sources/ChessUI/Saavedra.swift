import ChessCore

/// Saavedra's study. White underpromotes with c8=R, and the last move is Kb3.
enum Saavedra {
  static let board: Board = [
    .init(file: .b, rank: .six): .init(color: .white, figure: .king),
    .init(file: .c, rank: .six): .init(color: .white, figure: .pawn),
    .init(file: .a, rank: .one): .init(color: .black, figure: .king),
    .init(file: .d, rank: .five): .init(color: .black, figure: .rook)
  ]

  /// 1. c7 Rd6+ 2. Kb5 Rd5+ 3. Kb4 Rd4+ 4. Kb3 Rd3+ 5. Kc2 Rd4 6. c8=R Ra4 7. Kb3
  static let moves: [Move] = [
    pawn(.c, .seven),
    rook(.d, .six),
    king(.b, .five),
    rook(.d, .five),
    king(.b, .four),
    rook(.d, .four),
    king(.b, .three),
    rook(.d, .three),
    king(.c, .two),
    rook(.d, .four),
    pawn(.c, .eight, promotion: .rook),
    rook(.a, .four),
    king(.b, .three)
  ]

  private static func pawn(
    _ file: Square.File,
    _ rank: Square.Rank,
    promotion: Piece.Figure? = nil
  ) -> Move {
    .translation(.init(
      figure: .pawn,
      targetSquare: .init(file: file, rank: rank),
      promotion: promotion
    ))
  }

  private static func rook(_ file: Square.File, _ rank: Square.Rank) -> Move {
    .translation(.init(figure: .rook, targetSquare: .init(file: file, rank: rank)))
  }

  private static func king(_ file: Square.File, _ rank: Square.Rank) -> Move {
    .translation(.init(figure: .king, targetSquare: .init(file: file, rank: rank)))
  }
}
