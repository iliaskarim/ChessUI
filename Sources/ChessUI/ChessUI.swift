import ChessCore
import Foundation
import SwiftUI

// MARK: -
private extension Game {
  var isGameOver: Bool {
    switch status {
    case .toMove:
      false

    default:
      true
    }
  }
}

// MARK: - ChessUI
struct ChessUI: View {
  @StateObject private var viewModel = ViewModel(game: .init())

  @State private var showForfeitDialog = false

  @State private var showMenuDialog = false

  var body: some View {
    VStack {
      Text(viewModel.game.status.description).monospaced()

      VStack(spacing: 0) {
        ChessBoard(game: viewModel.game, isBoardFlipped: $viewModel.isBoardFlipped, isBoardLabeled: $viewModel.isBoardLabeled)
      }
      .padding([.leading, .bottom], viewModel.isBoardLabeled ? 12.0 : 16.0)
      .padding([.trailing, .top], 16.0)
      .background()
      .padding(1.0)
      .background(.red)

      HStack {
        Text(viewModel.game.board.status?.description ?? (viewModel.game.isGameOver ? "Game over" : " "))
          .monospaced()
          .fontWeight(.bold)

        Spacer()

        // Menu button
        Button {
          showMenuDialog.toggle()
        } label: {
          Image(systemName: "ellipsis")
        }
      }.padding(.horizontal, 2.0)
    }
    .fixedSize(horizontal: true, vertical: false)
    .padding()
    // MENU DIALOG
    .confirmationDialog("Menu", isPresented: $showMenuDialog) {
      if viewModel.game.isGameOver {
        Button("New game") {
          viewModel.newGame()
        }
      } else {
        Button("Forfeit game", role: .destructive) {
          showForfeitDialog.toggle()
        }
      }

      Button("Flip board") {
        viewModel.isBoardFlipped.toggle()
      }

      Button(viewModel.isBoardLabeled ? "Hide labels" : "Show labels") {
        viewModel.isBoardLabeled.toggle()
      }
    }

    // FORFEIT DIALOG
    .confirmationDialog("End this game?", isPresented: $showForfeitDialog, titleVisibility: .visible) {
      Button("Forfeit game", role: .destructive) {
        viewModel.forfeitGame()
      }
    }
  }
}

#Preview {
  ChessUI()
}
