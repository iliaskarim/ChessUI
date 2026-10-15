import ChessCore
import SwiftUI
#if os(iOS)
import UIKit
#endif

public struct ChessView: View {
  public var body: some View {
    VStack {
      Text(viewModel.game.status.description)
        .font(.callout)

      VStack(spacing: 0) {
        // CHESS BOARD
        ChessBoard(
          game: viewModel.game,
          isBoardFlipped: $viewModel.isBoardFlipped,
          isBoardLabeled: $viewModel.isBoardLabeled
        )
      }
      .padding([.leading, .bottom], viewModel.isBoardLabeled ? 12.0 : 16.0)
      .padding([.trailing, .top], 16.0)
      .background()
      .padding(1.0)
      .background(.black)

      HStack {
        // BOARD STATUS
        Text(viewModel.game.board.status?.description ?? (viewModel.game.isGameOver ? "Game over" : " "))
          .font(.caption)

        Spacer()

        // MENU BUTTON
        Button {
          showMenuDialog.toggle()
        } label: {
          Image(systemName: "ellipsis")
            .font(.caption)
        }
        // Anchored to the button so the popover sits above the ellipsis.
        .confirmationDialog("Menu", isPresented: $showMenuDialog) {
          // FLIP BOARD
          Button("Flip board") {
            viewModel.isBoardFlipped.toggle()
            SoundManager.shared.playWhoosh()
          }

          // TOGGLE LABELS
          Button(viewModel.isBoardLabeled ? "Hide labels" : "Show labels") {
            viewModel.isBoardLabeled.toggle()
            if viewModel.isBoardLabeled {
              SoundManager.shared.playKeypresssLoud()
            } else {
              SoundManager.shared.playKeypresssSoft()
            }
          }

          if viewModel.game.isGameOver {
            // NEW GAME
            Button("New game") {
              viewModel.newGame()
            }
          } else {
            // FORFEIT GAME
            Button("Forfeit game", role: .destructive) {
              showForfeitDialog.toggle()
            }
          }
        }
        .confirmationDialog(
          "End this game?",
          isPresented: $showForfeitDialog,
          titleVisibility: .visible
        ) {
          Button("Forfeit game", role: .destructive) {
            viewModel.forfeitGame()
          }
        }
      }.padding(.horizontal, 2.0)
    }
    .fixedSize(horizontal: true, vertical: false)
    .padding()
  }

  @StateObject private var viewModel = ChessViewViewModel()

  @State private var showForfeitDialog = false

  @State private var showMenuDialog = false

  public init() {}
}

#Preview {
  ChessView()
}

extension EnvironmentValues {
  @Entry var chessBoardDeselectCount: Int = 0
}

public extension View {
  /// `verticalShift` moves the board vertically inside the deselect target.
  /// Positive is down, matching `offset(y:)`. The shift is layout, so the
  /// menu popover stays on the ellipsis instead of the pre-shift frame.
  func deselectChessPieceOnBackgroundTap(verticalShift: CGFloat = 0) -> some View {
    modifier(ChessPieceBackgroundDeselectModifier(verticalShift: verticalShift))
  }
}

private struct BoardVerticalShift: ViewModifier {
  var shift: CGFloat

  func body(content: Content) -> some View {
    // A layout guide, not offset: popovers anchor to the laid-out frame.
    content.alignmentGuide(VerticalAlignment.center) { dimensions in
      dimensions[VerticalAlignment.center] - shift
    }
  }
}

private struct DeselectHoleKey: PreferenceKey {
  static var defaultValue: Anchor<CGRect>?

  static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
    value = nextValue() ?? value
  }
}

private struct ChessPieceBackgroundDeselectModifier: ViewModifier {
  var verticalShift: CGFloat = 0

  @State private var deselectCount = 0

  @State private var isHandlingPress = false

  func body(content: Content) -> some View {
#if os(iOS)
    // UIKit skips Color.clear, so the catcher is a real view. It only accepts
    // taps outside the chess view; the menu button and the pieces stay tappable.
    content
      .fixedSize()
      .anchorPreference(key: DeselectHoleKey.self, value: .bounds) { $0 }
      .modifier(BoardVerticalShift(shift: verticalShift))
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .backgroundPreferenceValue(DeselectHoleKey.self) { anchor in
        GeometryReader { geo in
          CatcherBacking(
            hole: anchor.map { geo[$0] } ?? .null,
            onPress: deselect,
            onRelease: endPress
          )
        }
      }
      .environment(\.chessBoardDeselectCount, deselectCount)
#else
    ZStack {
      Color.clear
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
        .modifier(PressAction(onPress: deselect, onRelease: endPress))
      content
        .fixedSize()
    }
    .modifier(BoardVerticalShift(shift: verticalShift))
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .environment(\.chessBoardDeselectCount, deselectCount)
#endif
  }

  private func deselect() {
    guard !isHandlingPress else {
      return
    }

    isHandlingPress = true
    deselectCount += 1
  }

  private func endPress() {
    isHandlingPress = false
  }
}

#if os(iOS)
private struct CatcherBacking: UIViewRepresentable {
  var hole: CGRect

  var onPress: () -> Void

  var onRelease: () -> Void

  func makeUIView(context _: Context) -> PressView {
    let view = PressView()
    view.hole = hole
    view.onPress = onPress
    view.onRelease = onRelease
    return view
  }

  func updateUIView(_ view: PressView, context _: Context) {
    view.hole = hole
    view.onPress = onPress
    view.onRelease = onRelease
  }

  final class PressView: UIView {
    var hole: CGRect = .null

    var onPress: () -> Void = {}

    var onRelease: () -> Void = {}

    override init(frame: CGRect) {
      super.init(frame: frame)
      backgroundColor = .clear
      isUserInteractionEnabled = true
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
      fatalError("init(coder:) has not been implemented")
    }

    override func point(inside point: CGPoint, with _: UIEvent?) -> Bool {
      guard !hole.isNull, bounds.contains(point) else {
        return false
      }

      return !hole.contains(point)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
      super.touchesBegan(touches, with: event)
      onPress()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
      super.touchesEnded(touches, with: event)
      onRelease()
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
      super.touchesCancelled(touches, with: event)
      onRelease()
    }
  }
}
#endif
