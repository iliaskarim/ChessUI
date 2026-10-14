#if os(iOS)
import UIKit

final class SceneDelegate: NSObject, UIWindowSceneDelegate {
  func scene(
    _: UIScene,
    willConnectTo _: UISceneSession,
    options _: UIScene.ConnectionOptions
  ) {
    AppSettingsStore.applyStoredInterfaceStyle()
  }
}
#endif
