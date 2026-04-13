import ChessCore
import Foundation
import SwiftUI

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
      .background(.red)

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
      }.padding(.horizontal, 2.0)
    }
    .fixedSize(horizontal: true, vertical: false)
    .padding()

    // MENU DIALOG
    .confirmationDialog("Menu", isPresented: $showMenuDialog) {
      // FLIP BOARD
      Button("Flip board") {
        viewModel.isBoardFlipped.toggle()
      }

      // TOGGLE LABELS
      Button(viewModel.isBoardLabeled ? "Hide labels" : "Show labels") {
        viewModel.isBoardLabeled.toggle()
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
    // FORFEIT DIALOG
    .confirmationDialog("End this game?", isPresented: $showForfeitDialog, titleVisibility: .visible) {
      Button("Forfeit game", role: .destructive) {
        viewModel.forfeitGame()
      }
    }
  }

  @StateObject private var viewModel = ChessViewViewModel()

  @State private var showForfeitDialog = false

  @State private var showMenuDialog = false

  public init() {}
}

#Preview {
  ChessView()
}
