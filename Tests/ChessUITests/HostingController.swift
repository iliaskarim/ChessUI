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
                    record recording: Bool? = nil,
                    timeout: TimeInterval = 5,
                    fileID: StaticString = #fileID,
                    file filePath: StaticString = #filePath,
                    testName: String = #function,
                    line: UInt = #line,
                    column: UInt = #column) {
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
