import Combine
import SwiftUI
import UIKit

@MainActor
final class AppSettingsStore: ObservableObject {
  enum SettingsKey: String {
    case userInterfaceStyle
  }

  var userInterfaceStyle: UIUserInterfaceStyle {
    get {
      UIUserInterfaceStyle(rawValue: userInterfaceStyleRaw) ?? .unspecified
    }
    set {
      userInterfaceStyleRaw = newValue.rawValue
      applyUserInterfaceStyleOverride()
    }
  }

  @AppStorage(SettingsKey.userInterfaceStyle.rawValue)
  private var userInterfaceStyleRaw = UIUserInterfaceStyle.unspecified.rawValue

  private func applyUserInterfaceStyleOverride() {
    UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .forEach {
        $0.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: userInterfaceStyleRaw) ?? .unspecified
      }
  }
}
