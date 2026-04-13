import XCTest
@testable import ChessUI

final class ChessUITests: XCTestCase {
  func testChessUI() {
    let chessUI = ChessView()

    assertSnapshot(chessUI)
  }
}
