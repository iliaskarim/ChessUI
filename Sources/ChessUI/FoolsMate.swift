import ChessCore

enum FoolsMate {
  static let moves: [Move] = [
    .translation(.init(figure: .pawn, targetSquare: .init(file: .f, rank: .three))),
    .translation(.init(figure: .pawn, targetSquare: .init(file: .e, rank: .five))),
    .translation(.init(figure: .pawn, targetSquare: .init(file: .g, rank: .four))),
    .translation(.init(figure: .queen, targetSquare: .init(file: .h, rank: .four)))
  ]
}
