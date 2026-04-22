import AVFoundation

@MainActor
final class SoundManager {
  static let shared = SoundManager()

  func playPop3() {
    play("Pop 3 by DSG", ext: "flac")
  }

  func playPop7() {
    play("Pop 7 by DSG", ext: "flac")
  }

  func playPop8() {
    play("Pop 8 by DSG", ext: "flac")
  }

  private init() {}

  private var player: AVAudioPlayer?

  private func play(_ name: String, ext: String) {
    guard let url = Bundle.module.url(forResource: name, withExtension: ext) else {
      print("Sound file not found: \(name).\(ext)")
#if DEBUG
      fatalError()
#else
      return
#endif
    }

    do {
      player = try AVAudioPlayer(contentsOf: url)
      player?.prepareToPlay()
      player?.play()
    } catch {
      print("Failed to play sound: \(error)")
    }
  }
}
