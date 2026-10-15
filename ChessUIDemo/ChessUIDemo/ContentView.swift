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
        // The toolbar shrinks the content region. Shift only the board so it
        // stays centered on the full screen, and leave the deselect target
        // filling that region at its real size.
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
