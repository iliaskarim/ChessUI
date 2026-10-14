import SnapshotTesting
import SwiftUI
#if os(iOS)
import UIKit
#endif
import XCTest

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
