#if os(iOS)
import SwiftUI
import UIKit

public typealias HostingController = UIHostingController
#elseif os(macOS)
import AppKit
import SwiftUI

public typealias HostingController = NSHostingController
#endif

import SnapshotTesting

func assertSnapshot(_ content: some View,
                    colorScheme: ColorScheme? = nil,
                    record recording: Bool? = nil,
                    timeout: TimeInterval = 5,
                    fileID: StaticString = #fileID,
                    file filePath: StaticString = #filePath,
                    testName: String = #function,
                    line: UInt = #line,
                    column: UInt = #column) {
  if let colorScheme {
    let controller = HostingController(
      rootView: content.environment(\.colorScheme, colorScheme)
    )
#if os(iOS)
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
#elseif os(macOS)
    controller.view.appearance = NSAppearance(named: colorScheme == .dark ? .darkAqua : .aqua)
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
  } else {
    assertSnapshot(of: HostingController(rootView: content),
                   as: .image,
                   record: recording,
                   timeout: timeout,
                   fileID: fileID,
                   file: filePath,
                   testName: testName,
                   line: line,
                   column: column)
  }
}
