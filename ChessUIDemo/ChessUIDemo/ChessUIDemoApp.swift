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

  @UIApplicationDelegateAdaptor(AppDelegate.self)
  private var appDelegate

  @StateObject private var appSettings = AppSettingsStore()
}
