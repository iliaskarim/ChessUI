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
          .font(.callout)

      case .light:
        Image(systemName: "sun.max")
          .font(.callout)

      case .unspecified:
        Image(systemName: colorScheme == .dark ? "moon" : "sun.max")
          .font(.callout)

      @unknown default:
        Image(systemName: colorScheme == .dark ? "moon" : "sun.max")
          .font(.callout)
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
