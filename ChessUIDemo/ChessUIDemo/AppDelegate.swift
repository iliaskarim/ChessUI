#if os(iOS)
import UIKit

final class AppDelegate: NSObject, UIApplicationDelegate {
  func application(
    _: UIApplication,
    configurationForConnecting connectingSceneSession: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) -> UISceneConfiguration {
    let config = UISceneConfiguration(
      name: "Default Configuration",
      sessionRole: connectingSceneSession.role
    )
    config.delegateClass = SceneDelegate.self
    return config
  }
}
#elseif os(macOS)
import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
  func applicationDidFinishLaunching(_: Notification) {
    AppSettingsStore.applyStoredInterfaceStyle()
  }
}
#endif
