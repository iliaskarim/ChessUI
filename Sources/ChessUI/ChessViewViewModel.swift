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
      try? await Task.sleep(for: .milliseconds(1000))
      if selected, let target = targetSquare(of: move) {
        activateAccessibilityElement(target.description)
        if let choice = promotionChoice(of: move) {
          // Leave the menu on screen, then pick the piece through its button.
          try? await Task.sleep(for: .milliseconds(1000))
          activateAccessibilityElement(choice.identifier, label: choice.label)
        }
      }
#else
      try? await Task.sleep(for: .milliseconds(1000))
      play(move)
#endif
      try? await Task.sleep(for: .milliseconds(1200))
    }
    return true
  }

#if os(iOS)
  private func targetSquare(of move: Move) -> Square? {
    switch move {
    case let .translation(translation):
      return translation.targetSquare

    case let .castling(castling):
      guard case let .toMove(color) = game.status else {
        return nil
      }

      let rank: Square.Rank = color == .white ? .one : .eight
      let file: Square.File = castling == .kingside ? .g : .c
      return Square(file: file, rank: rank)
    }
  }

  private func promotionChoice(of move: Move) -> (identifier: String, label: String)? {
    guard case let .translation(translation) = move, let promotion = translation.promotion else {
      return nil
    }

    switch promotion {
    case .queen:
      return ("promotion-queen", "Promote pawn to queen")

    case .rook:
      return ("promotion-rook", "Promote pawn to rook")

    case .bishop:
      return ("promotion-bishop", "Promote pawn to bishop")

    case .knight:
      return ("promotion-knight", "Promote pawn to knight")

    case .king, .pawn:
      return nil
    }
  }

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
