import SwiftUI

struct PressAction: ViewModifier {
  var onPress: () -> Void

  var onRelease: (() -> Void)?

  /// `onChanged` also fires for movement later in the same press.
  @State private var isPressed = false

  func body(content: Content) -> some View {
    content.simultaneousGesture(DragGesture(minimumDistance: 0)
      .onChanged { _ in
        guard !isPressed else {
          return
        }

        isPressed = true
        onPress()
      }
      .onEnded { _ in
        isPressed = false
        onRelease?()
      })
  }
}
