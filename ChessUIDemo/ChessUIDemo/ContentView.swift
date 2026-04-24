import ChessUI
import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationStack {
      GeometryReader { proxy in
        ChessView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          // Navigation toolbar reduces the content region; compensate so the board
          // stays visually centered in the full screen.
          .offset(y: (UIScreen.main.bounds.midY - proxy.frame(in: .global).midY))
      }
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          DarkModePickerMenu()
        }
      }
      .toolbarTitleDisplayMode(.inline)
    }
  }
}

#Preview {
  ContentView()
    .environmentObject(AppSettingsStore())
}
