import SwiftUI
import XCTest
@testable import ChessUI

final class ChessBoardTests: XCTestCase {
  func testLabeledChessBoard() {
    assertSnapshot(ChessBoard(game: .init(), isBoardFlipped: .constant(false), isBoardLabeled: .constant(true)))
  }

  func testFlippedLabeledChessBoard() {
    assertSnapshot(ChessBoard(game: .init(), isBoardFlipped: .constant(true), isBoardLabeled: .constant(true)))
  }

  func testFlippedUnlabeledChessBoard() {
    assertSnapshot(ChessBoard(game: .init(), isBoardFlipped: .constant(true), isBoardLabeled: .constant(false)))
  }

  func testUnlabeledChessBoard() {
    assertSnapshot(ChessBoard(game: .init(), isBoardFlipped: .constant(false), isBoardLabeled: .constant(false)))
  }
}
