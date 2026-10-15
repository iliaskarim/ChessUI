import SwiftUI

struct DarkModePickerMenu: View {
  var body: some View {
    Menu {
      Picker("Theme", selection: themeBinding) {
        Text("System").tag(Theme.system)
        Text("Light").tag(Theme.light)
        Text("Dark").tag(Theme.dark)
      }
      .pickerStyle(.inline)
      .labelsHidden()
    } label: {
      switch themeBinding.wrappedValue {
      case .dark:
        Image(systemName: "moon")
          .font(.callout)

      case .light:
        Image(systemName: "sun.max")
          .font(.callout)

      case .system:
        Image(systemName: colorScheme == .dark ? "moon" : "sun.max")
          .font(.callout)
      }
    }
  }

  @EnvironmentObject private var appSettingsStore: AppSettingsStore

  @Environment(\.colorScheme)
  private var colorScheme

  private var themeBinding: Binding<Theme> {
    Binding(
      get: {
        appSettingsStore.theme
      },
      set: { newValue in
        appSettingsStore.theme = newValue
      }
    )
  }
}

#Preview {
  DarkModePickerMenu()
    .environmentObject(AppSettingsStore())
}
