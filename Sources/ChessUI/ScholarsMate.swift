import ChessCore

/// Scholar's mate. White's last move is Qxf7#.
enum ScholarsMate {
  static let moves: [Move] = [
    .translation(.init(figure: .pawn, targetSquare: .init(file: .e, rank: .four))),
    .translation(.init(figure: .pawn, targetSquare: .init(file: .e, rank: .five))),
    .translation(.init(figure: .queen, targetSquare: .init(file: .h, rank: .five))),
    .translation(.init(figure: .knight, targetSquare: .init(file: .c, rank: .six))),
    .translation(.init(figure: .bishop, targetSquare: .init(file: .c, rank: .four))),
    .translation(.init(figure: .knight, targetSquare: .init(file: .f, rank: .six))),
    .translation(.init(
      figure: .queen,
      targetSquare: .init(file: .f, rank: .seven),
      isCapture: true
    ))
  ]
}
