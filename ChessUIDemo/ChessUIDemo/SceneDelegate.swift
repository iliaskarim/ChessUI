import UIKit

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
  func scene(
    _ scene: UIScene,
    willConnectTo _: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) {
    (scene as? UIWindowScene)?.windows.forEach {
      $0.overrideUserInterfaceStyle = UIUserInterfaceStyle(
        rawValue: UserDefaults.standard.integer(
          forKey: AppSettingsStore.SettingsKey.userInterfaceStyle.rawValue
        )
      ) ?? .unspecified
    }
  }
}
