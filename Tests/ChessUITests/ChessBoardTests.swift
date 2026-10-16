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

  func testBoardSquareMatchesItsCenter() {
    let scale = 30.0
    for isFlipped in [false, true] {
      for file in Square.File.allCases {
        for rank in Square.Rank.allCases {
          let square = Square(file: file, rank: rank)
          let center = boardSquareCenter(square, scale: scale, isFlipped: isFlipped)
          XCTAssertEqual(
            boardSquare(at: center, scale: scale, isFlipped: isFlipped),
            square
          )
        }
      }
    }

    XCTAssertEqual(
      boardSquare(at: CGPoint(x: 15, y: 15), scale: scale, isFlipped: false),
      Square(file: .a, rank: .eight)
    )
    XCTAssertEqual(
      boardSquare(at: CGPoint(x: 135, y: 195), scale: scale, isFlipped: false),
      Square(file: .e, rank: .two)
    )
    XCTAssertEqual(
      boardSquare(at: CGPoint(x: 15, y: 15), scale: scale, isFlipped: true),
      Square(file: .h, rank: .one)
    )
    XCTAssertNil(boardSquare(at: CGPoint(x: -1, y: 10), scale: scale, isFlipped: false))
    XCTAssertNil(boardSquare(at: CGPoint(x: 240, y: 10), scale: scale, isFlipped: false))
  }

  func testEPawnMoves() throws {
    try assertSnapshot(
      selecting: "e2",
      ChessBoard(
        game: .init(),
        isBoardFlipped: .constant(false),
        isBoardLabeled: .constant(false)
      )
    )
  }
}
