import XCTest
@testable import ChessUI

final class ChessUITests: XCTestCase {
  func testChessUI() throws {
    let chessUI = ChessView()

    try assertSnapshot(chessUI)
  }

  func testChessUIDarkMode() throws {
    try assertSnapshot(ChessView(), colorScheme: .dark)
  }
}
