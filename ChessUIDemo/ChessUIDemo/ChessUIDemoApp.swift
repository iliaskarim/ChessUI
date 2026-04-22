import ChessUI
import SwiftUI

@main
struct ChessUIDemoApp: App {
  var body: some Scene {
    WindowGroup {
      ChessView()
        .tint(.primary)
    }
  }
}
