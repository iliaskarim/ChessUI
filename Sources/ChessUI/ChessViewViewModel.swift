import ChessCore
import Combine
import SwiftUI

final class ChessViewViewModel: ObservableObject {
  @ObservedObject private(set) var game: Game

  @AppStorage("flipBoard")
  var isBoardFlipped = false

  @AppStorage("labelBoard")
  var isBoardLabeled = false

  private var cancellables = Set<AnyCancellable>()

  func forfeitGame() {
    guard case let .toMove(toMove) = game.status else {
      return
    }

    try! game.endGame(victor: toMove.opposite)
  }

  func newGame() {
    game = Game()
    setupObservation()
  }

  init(game: Game = Game()) {
    self.game = game
    setupObservation()
  }

  private func setupObservation() {
    cancellables.removeAll()

    game.objectWillChange
      .sink { [weak self] _ in
        self?.objectWillChange.send()
      }
      .store(in: &cancellables)
  }
}
