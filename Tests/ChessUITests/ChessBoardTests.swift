import ChessCore
import SwiftUI
import XCTest
@testable import ChessUI

final class ChessBoardTests: XCTestCase {
  func testLabeledChessBoard() throws {
    try assertSnapshot(
      ChessBoard(
        game: .init(),
        isBoardFlipped: .constant(false),
        isBoardLabeled: .constant(true)
      )
    )
  }

  func testFlippedLabeledChessBoard() throws {
    try assertSnapshot(
      ChessBoard(
        game: .init(),
        isBoardFlipped: .constant(true),
        isBoardLabeled: .constant(true)
      )
    )
  }

  func testFlippedUnlabeledChessBoard() throws {
    try assertSnapshot(
      ChessBoard(
        game: .init(),
        isBoardFlipped: .constant(true),
        isBoardLabeled: .constant(false)
      )
    )
  }

  func testUnlabeledChessBoard() throws {
    try assertSnapshot(
      ChessBoard(
        game: .init(),
        isBoardFlipped: .constant(false),
        isBoardLabeled: .constant(false)
      )
    )
  }

  func testEPawnMoves() throws {
    try assertSnapshot(
      ChessBoard(
        game: .init(),
        isBoardFlipped: .constant(false),
        isBoardLabeled: .constant(false),
        previewedSquare: .constant(Square(file: .e, rank: .two))
      )
    )
  }
}
