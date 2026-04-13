import ChessCore

extension Game {
  var isGameOver: Bool {
    switch status {
    case .toMove:
      false

    default:
      true
    }
  }
}
