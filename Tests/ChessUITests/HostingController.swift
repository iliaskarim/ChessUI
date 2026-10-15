import SnapshotTesting
import SwiftUI
#if os(iOS)
import UIKit
#endif
import XCTest

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

  let selected = waitForAccessibilityActivation(
    of: identifier,
    in: controller.view,
    timeout: timeout
  )
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

private func waitForAccessibilityActivation(of identifier: String,
                                            in view: UIView,
                                            timeout: TimeInterval) -> Bool {
  let deadline = Date().addingTimeInterval(timeout)
  while Date() < deadline {
    if let element = accessibilityElement(identifier: identifier, in: view),
       element.accessibilityActivate() {
      return true
    }

    RunLoop.current.run(until: Date().addingTimeInterval(0.05))
  }

  return false
}

private func accessibilityElement(identifier: String, in object: Any) -> NSObject? {
  var seen: Set<ObjectIdentifier> = []
  return accessibilityElement(identifier: identifier, in: object, seen: &seen)
}

private func accessibilityElement(identifier: String,
                                  in object: Any,
                                  seen: inout Set<ObjectIdentifier>) -> NSObject? {
  if let object = object as? NSObject {
    let identity = ObjectIdentifier(object)
    guard seen.insert(identity).inserted else {
      return nil
    }

    if isAccessibilityNode(object), nodeHasIdentifier(object, identifier) {
      return object
    }
    if (object as? UIAccessibilityIdentification)?.accessibilityIdentifier == identifier {
      return object
    }
  }

  for child in accessibilityChildren(of: object) {
    if let found = accessibilityElement(identifier: identifier, in: child, seen: &seen) {
      return found
    }
  }
  return nil
}

private func isAccessibilityNode(_ object: NSObject) -> Bool {
  String(describing: type(of: object)) == "AccessibilityNode"
}

private func nodeHasIdentifier(_ object: NSObject, _ identifier: String) -> Bool {
  containsString(identifier, in: object, depth: 0, skippingChildren: true)
}

private func accessibilityChildren(of object: Any) -> [Any] {
  var children: [Any] = []
  let mirror = Mirror(reflecting: object)
  for child in mirror.children where child.label == "children" {
    if let list = child.value as? [Any] {
      children.append(contentsOf: list)
    }
  }
  if let object = object as? NSObject {
    children.append(contentsOf: object.accessibilityElements ?? [])
  }
  if let view = object as? UIView {
    children.append(contentsOf: view.subviews)
  }
  return children
}

private func containsString(_ identifier: String,
                            in value: Any,
                            depth: Int,
                            skippingChildren: Bool) -> Bool {
  if depth > 8 {
    return false
  }
  if let text = value as? String {
    return text == identifier
  }

  let mirror = Mirror(reflecting: value)
  for child in mirror.children {
    switch child.label {
    case "parent", "environment", "viewRendererHost":
      continue

    case "children" where skippingChildren:
      continue

    default:
      if containsString(identifier, in: child.value, depth: depth + 1, skippingChildren: false) {
        return true
      }
    }
  }
  return false
}
#endif
