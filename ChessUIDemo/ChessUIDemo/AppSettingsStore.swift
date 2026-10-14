import Combine
import SwiftUI
#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

enum Theme: Int {
  case system = 0
  case light = 1
  case dark = 2
}

@MainActor
final class AppSettingsStore: ObservableObject {
  enum SettingsKey: String {
    case userInterfaceStyle
  }

  var theme: Theme {
    get {
      Theme(rawValue: themeRaw) ?? .system
    }
    set {
      themeRaw = newValue.rawValue
      Self.applyStoredInterfaceStyle()
    }
  }

  static func applyStoredInterfaceStyle() {
    let raw = UserDefaults.standard.integer(forKey: SettingsKey.userInterfaceStyle.rawValue)
    let theme = Theme(rawValue: raw) ?? .system
#if os(iOS)
    let style: UIUserInterfaceStyle =
      switch theme {
      case .system:
        .unspecified

      case .light:
        .light

      case .dark:
        .dark
      }
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .forEach { window in
        window.overrideUserInterfaceStyle = style
      }
#elseif os(macOS)
    let appearance: NSAppearance? =
      switch theme {
      case .system:
        nil

      case .light:
        NSAppearance(named: .aqua)

      case .dark:
        NSAppearance(named: .darkAqua)
      }
    NSApp.appearance = appearance
    NSApp.windows.forEach { $0.appearance = appearance }
#endif
  }

  @AppStorage(SettingsKey.userInterfaceStyle.rawValue)
  private var themeRaw = Theme.system.rawValue
}
