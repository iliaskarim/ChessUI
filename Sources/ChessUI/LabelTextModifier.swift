import SwiftUI

struct LabelTextModifier: ViewModifier {
  func body(content: Content) -> some View {
    content
      .monospaced()
      .font(.system(size: 13.0))
  }
}

extension View {
  func labelTextStyle() -> some View {
    modifier(LabelTextModifier())
  }
}
