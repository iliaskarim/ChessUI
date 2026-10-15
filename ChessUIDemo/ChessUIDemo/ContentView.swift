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

  @State private var boardShift: CGFloat = 0

  @ViewBuilder
  private var board: some View {
#if os(iOS)
    ChessView()
      // The toolbar shrinks the content region. Shift only the board so it
      // stays centered on the full screen, and leave the deselect target
      // filling that region at its real size. Measure from the background:
      // a GeometryReader or offset around the board sends the menu popover
      // to the top of the screen instead of the ellipsis button.
      .deselectChessPieceOnBackgroundTap(verticalShift: boardShift)
      .background {
        GeometryReader { proxy in
          Color.clear.preference(
            key: BoardCenterShiftKey.self,
            value: UIScreen.main.bounds.midY - proxy.frame(in: .global).midY
          )
        }
      }
      .onPreferenceChange(BoardCenterShiftKey.self) { boardShift = $0 }
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

private struct BoardCenterShiftKey: PreferenceKey {
  static var defaultValue: CGFloat = 0

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = nextValue()
  }
}

#Preview {
  ContentView()
    .environmentObject(AppSettingsStore())
}
