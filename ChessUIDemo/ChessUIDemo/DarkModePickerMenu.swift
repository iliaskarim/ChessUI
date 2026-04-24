import SwiftUI

struct DarkModePickerMenu: View {
  var body: some View {
    Menu {
      Picker("Theme", selection: userInterfaceStyleBinding) {
        Text("System").tag(UIUserInterfaceStyle.unspecified)
        Text("Light").tag(UIUserInterfaceStyle.light)
        Text("Dark").tag(UIUserInterfaceStyle.dark)
      }
    } label: {
      switch userInterfaceStyleBinding.wrappedValue {
      case .dark:
        Image(systemName: "moon")

      case .light:
        Image(systemName: "sun.max")

      case .unspecified:
        Image(systemName: colorScheme == .dark ? "moon" : "sun.max")

      @unknown default:
        Image(systemName: colorScheme == .dark ? "moon" : "sun.max")
      }
    }
  }

  @EnvironmentObject private var appSettingsStore: AppSettingsStore

  @Environment(\.colorScheme) private var colorScheme

  private var userInterfaceStyleBinding: Binding<UIUserInterfaceStyle> {
    Binding<UIUserInterfaceStyle>(
      get: {
        appSettingsStore.userInterfaceStyle
      },
      set: { newValue in
        appSettingsStore.userInterfaceStyle = newValue
      }
    )
  }
}

#Preview {
  DarkModePickerMenu()
    .environmentObject(AppSettingsStore())
}
