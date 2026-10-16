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

  private var replayStarted = false

  @MainActor
  func forfeitGame() {
    guard case let .toMove(toMove) = game.status else {
      return
    }

    try! game.endGame(victor: toMove.opposite)
    SoundManager.shared.playTrumpetFanfare()
  }

  func newGame() {
    game = Game()
    setupObservation()
  }

  @MainActor
  @discardableResult
  func play(_ move: Move) -> String {
    let isCapture: Bool = if case let .translation(translation) = move {
      translation.isCapture
    } else {
      false
    }

    try! game.play(move)
    return SoundManager.shared.playMove(
      move,
      status: game.status,
      boardStatus: game.board.status,
      isCapture: isCapture
    )
  }

  @MainActor
  func runReplay(_ moves: [Move]) async -> Bool {
    guard !moves.isEmpty, !replayStarted else {
      return false
    }

    replayStarted = true
    ReplayRecorder.shared.start()
    defer {
      ReplayRecorder.shared.stop()
      replayStarted = false
    }

    try? await Task.sleep(for: .milliseconds(1500))
    for move in moves {
#if os(iOS)
      let square = origin(of: move)
      let selected = square.map { activateAccessibilityElement($0.description) } ?? false
#endif
      try? await Task.sleep(for: .milliseconds(1000))
#if os(iOS)
      if selected, let square {
        activateAccessibilityElement(square.description)
      }
#endif
      play(move)
      try? await Task.sleep(for: .milliseconds(1200))
    }
    return true
  }

#if os(iOS)
  private func origin(of move: Move) -> Square? {
    var match: Square?
    for file in Square.File.allCases {
      for rank in Square.Rank.allCases {
        let square = Square(file: file, rank: rank)
        let plays = game.board.moves(from: square).values.contains { candidates in
          candidates.contains { isSameMove($0, move) }
        }
        guard plays else {
          continue
        }

        guard match == nil else {
          return nil
        }

        match = square
      }
    }
    return match
  }

  private func isSameMove(_ candidate: Move, _ move: Move) -> Bool {
    switch (candidate, move) {
    case let (.castling(candidateCastling), .castling(moveCastling)):
      return switch (candidateCastling, moveCastling) {
      case (.kingside, .kingside), (.queenside, .queenside):
        true

      default:
        false
      }

    case let (.translation(candidateTranslation), .translation(moveTranslation)):
      if let file = moveTranslation.disambiguationFile, file != candidateTranslation.disambiguationFile {
        return false
      }

      if let rank = moveTranslation.disambiguationRank, rank != candidateTranslation.disambiguationRank {
        return false
      }

      return candidateTranslation.figure == moveTranslation.figure
        && candidateTranslation.isCapture == moveTranslation.isCapture
        && candidateTranslation.targetSquare == moveTranslation.targetSquare
        && candidateTranslation.promotion == moveTranslation.promotion

    default:
      return false
    }
  }
#endif

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
