import ChessUI
import SwiftUI

struct ContentView: View {
  var body: some View {
    NavigationStack {
      board
        .toolbar { themeMenu }
#if os(iOS)
        .toolbarTitleDisplayMode(.inline)
#endif
    }
  }

  @ViewBuilder
  private var board: some View {
#if os(iOS)
    GeometryReader { proxy in
      ChessView()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Navigation toolbar reduces the content region; compensate so the board
        // stays visually centered in the full screen. The deselect target stays
        // in the content region so taps around the shifted board still land.
        .offset(y: UIScreen.main.bounds.midY - proxy.frame(in: .global).midY)
        .deselectChessPieceOnBackgroundTap()
    }
#else
    ChessView()
      .deselectChessPieceOnBackgroundTap()
      .frame(maxWidth: .infinity, maxHeight: .infinity)
#endif
  }

  @ToolbarContentBuilder
  private var themeMenu: some ToolbarContent {
#if os(iOS)
    ToolbarItem(placement: .topBarLeading) {
      DarkModePickerMenu()
    }
#else
    ToolbarItem(placement: .automatic) {
      DarkModePickerMenu()
    }
#endif
  }
}

#Preview {
  ContentView()
    .environmentObject(AppSettingsStore())
}
