import SwiftUI

@main
struct ChessUIDemoApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
        .tint(.primary)
    }
    .environmentObject(appSettings)
  }

#if os(iOS)
  @UIApplicationDelegateAdaptor(AppDelegate.self)
  private var appDelegate
#elseif os(macOS)
  @NSApplicationDelegateAdaptor(AppDelegate.self)
  private var appDelegate
#endif

  @StateObject private var appSettings = AppSettingsStore()
}
