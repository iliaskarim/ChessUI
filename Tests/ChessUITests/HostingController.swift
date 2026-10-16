import SnapshotTesting
import SwiftUI
#if os(iOS)
import UIKit
#endif
import XCTest
#if os(iOS)
@testable import ChessUI
#endif

func assertSnapshot(selecting identifier: String,
                    _ content: some View,
                    record recording: Bool? = nil,
                    timeout: TimeInterval = 5,
                    fileID: StaticString = #fileID,
                    file filePath: StaticString = #filePath,
                    testName: String = #function,
                    line: UInt = #line,
                    column: UInt = #column) throws {
#if os(macOS)
  throw XCTSkip("Snapshots are recorded on the iOS simulator. Run `just test`.")
#else
  let controller = UIHostingController(rootView: content)
  controller.view.frame = .zero
  controller.view.sizeToFit()
  let fitted = controller.view.frame.size

  let window = snapshotWindow()
  window.frame = CGRect(origin: .zero, size: fitted)
  window.rootViewController = controller
  window.makeKeyAndVisible()
  controller.view.layoutIfNeeded()

  let selected = activateAccessibilityElement(identifier, in: controller.view, timeout: timeout)
  XCTAssertTrue(selected, "Could not select \(identifier).", file: filePath, line: line)
  RunLoop.current.run(until: Date().addingTimeInterval(0.1))

  window.isHidden = true
  window.rootViewController = nil
  controller.view.frame = CGRect(origin: .zero, size: fitted)

  assertSnapshot(of: controller,
                 as: .image,
                 record: recording,
                 timeout: timeout,
                 fileID: fileID,
                 file: filePath,
                 testName: testName,
                 line: line,
                 column: column)
#endif
}

func assertSnapshot(_ content: some View,
                    colorScheme: ColorScheme? = nil,
                    record recording: Bool? = nil,
                    timeout: TimeInterval = 5,
                    fileID: StaticString = #fileID,
                    file filePath: StaticString = #filePath,
                    testName: String = #function,
                    line: UInt = #line,
                    column: UInt = #column) throws {
#if os(macOS)
  throw XCTSkip("Snapshots are recorded on the iOS simulator. Run `just test`.")
#else
  if let colorScheme {
    let controller = UIHostingController(
      rootView: content.environment(\.colorScheme, colorScheme)
    )
    let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
    controller.overrideUserInterfaceStyle = style
    assertSnapshot(of: controller,
                   as: .image(traits: .init(userInterfaceStyle: style)),
                   record: recording,
                   timeout: timeout,
                   fileID: fileID,
                   file: filePath,
                   testName: testName,
                   line: line,
                   column: column)
  } else {
    assertSnapshot(of: UIHostingController(rootView: content),
                   as: .image,
                   record: recording,
                   timeout: timeout,
                   fileID: fileID,
                   file: filePath,
                   testName: testName,
                   line: line,
                   column: column)
  }
#endif
}

#if os(iOS)
private func snapshotWindow() -> UIWindow {
  let scene = UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .first { $0.activationState != .unattached }
  if let scene {
    return UIWindow(windowScene: scene)
  }

  return UIWindow(frame: CGRect(x: 0, y: 0, width: 400, height: 400))
}

#endif
