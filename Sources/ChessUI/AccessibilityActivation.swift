#if os(iOS)
import UIKit

/// SwiftUI keeps the identifier on its accessibility node, which unit tests and
/// in-process replay can activate. `UIAccessibilityIdentification` stays empty.
/// Call on the main thread.
@discardableResult
func activateAccessibilityElement(_ identifier: String,
                                  in root: Any? = nil,
                                  timeout: TimeInterval = 5) -> Bool {
  let deadline = Date().addingTimeInterval(timeout)
  while Date() < deadline {
    let roots = root.map { [$0] } ?? accessibilityRoots()
    for candidate in roots {
      if let element = accessibilityElement(identifier: identifier, in: candidate),
         element.accessibilityActivate() {
        return true
      }
    }

    RunLoop.current.run(until: Date().addingTimeInterval(0.05))
  }

  return false
}

private func accessibilityRoots() -> [Any] {
  UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .flatMap(\.windows)
    .compactMap { $0.rootViewController?.view }
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
