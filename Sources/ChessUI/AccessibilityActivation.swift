#if os(iOS)
import ObjectiveC
import UIKit

/// SwiftUI keeps the identifier on its accessibility node, which unit tests and
/// in-process replay can activate. A confirmation dialog's buttons are UIKit
/// action views: the identifier does not arrive, the label is the button title,
/// and `accessibilityActivate()` returns false, so replay runs that alert action.
/// Call on the main thread.
@discardableResult
func activateAccessibilityElement(_ identifier: String,
                                  label: String? = nil,
                                  in root: Any? = nil,
                                  timeout: TimeInterval = 5) -> Bool {
  let deadline = Date().addingTimeInterval(timeout)
  while Date() < deadline {
    let roots = root.map { [$0] } ?? accessibilityRoots()
    for candidate in roots {
      if let element = accessibilityElement(identifier: identifier, label: label, in: candidate),
         press(element) {
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
    .flatMap { window -> [Any] in
      var roots: [Any] = window.subviews
      if let controller = window.rootViewController {
        roots.append(contentsOf: controllerViews(controller))
      }
      return roots
    }
}

private func controllerViews(_ controller: UIViewController) -> [UIView] {
  var views: [UIView] = []
  if let view = controller.viewIfLoaded {
    views.append(view)
  }
  if let presented = controller.presentedViewController {
    views.append(contentsOf: controllerViews(presented))
  }
  for child in controller.children {
    views.append(contentsOf: controllerViews(child))
  }
  return views
}

private func accessibilityElement(identifier: String, label: String?, in object: Any) -> NSObject? {
  var seen: Set<ObjectIdentifier> = []
  return accessibilityElement(identifier: identifier, label: label, in: object, seen: &seen)
}

private func accessibilityElement(identifier: String,
                                  label: String?,
                                  in object: Any,
                                  seen: inout Set<ObjectIdentifier>) -> NSObject? {
  if let object = object as? NSObject {
    let identity = ObjectIdentifier(object)
    guard seen.insert(identity).inserted else {
      return nil
    }

    if isAccessibilityNode(object), nodeMatches(object, identifier: identifier, label: label) {
      return object
    }
    if (object as? UIAccessibilityIdentification)?.accessibilityIdentifier == identifier {
      return object
    }
    if let label, object.accessibilityLabel == label {
      return object
    }
  }

  for child in accessibilityChildren(of: object) {
    if let found = accessibilityElement(identifier: identifier, label: label, in: child, seen: &seen) {
      return found
    }
  }
  return nil
}

/// Squares implement `accessibilityActivate()`. A confirmation dialog's buttons
/// are UIKit action views whose activate call returns false, so run the alert
/// action with that title and dismiss the dialog.
private func press(_ element: NSObject) -> Bool {
  if element.accessibilityActivate() {
    return true
  }

  guard let label = element.accessibilityLabel else {
    return false
  }

  return pressAlertAction(titled: label)
}

private func pressAlertAction(titled label: String) -> Bool {
  guard let (alert, action) = presentedAlertAction(titled: label),
        invokeHandler(of: action) else {
    return false
  }

  alert.dismiss(animated: true)
  return true
}

private func presentedAlertAction(titled label: String) -> (UIAlertController, UIAlertAction)? {
  let controllers = UIApplication.shared.connectedScenes
    .compactMap { $0 as? UIWindowScene }
    .flatMap(\.windows)
    .compactMap(\.rootViewController)
  for controller in controllers {
    if let match = alertAction(titled: label, from: controller) {
      return match
    }
  }
  return nil
}

private func alertAction(titled label: String,
                         from controller: UIViewController) -> (UIAlertController, UIAlertAction)? {
  if let alert = controller as? UIAlertController,
     let action = alert.actions.first(where: { $0.title == label }) {
    return (alert, action)
  }

  if let presented = controller.presentedViewController,
     let match = alertAction(titled: label, from: presented) {
    return match
  }

  for child in controller.children {
    if let match = alertAction(titled: label, from: child) {
      return match
    }
  }
  return nil
}

private func invokeHandler(of action: UIAlertAction) -> Bool {
  guard let ivar = handlerIvar(of: action),
        let value = object_getIvar(action, ivar) else {
    return false
  }

  typealias Handler = @convention(block) (UIAlertAction) -> Void
  let handler = unsafeBitCast(value as AnyObject, to: Handler.self)
  handler(action)
  return true
}

private func handlerIvar(of action: UIAlertAction) -> Ivar? {
  var current: AnyClass? = object_getClass(action)
  while let cls = current {
    if let ivar = class_getInstanceVariable(cls, "_handler") {
      return ivar
    }
    current = class_getSuperclass(cls)
  }
  return nil
}

private func isAccessibilityNode(_ object: NSObject) -> Bool {
  String(describing: type(of: object)) == "AccessibilityNode"
}

private func nodeMatches(_ object: NSObject, identifier: String, label: String?) -> Bool {
  if nodeHasIdentifier(object, identifier) {
    return true
  }

  guard let label else {
    return false
  }

  return nodeHasIdentifier(object, label)
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
