import ChessCore

extension [Move] {
  func promotion(figure: Piece.Figure) -> Move? {
    first { play in
      if case let .translation(translation) = play, translation.promotion == figure {
        true
      } else {
        false
      }
    }
  }
}
