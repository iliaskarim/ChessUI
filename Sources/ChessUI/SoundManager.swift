import AVFoundation

@MainActor
final class SoundManager {
  static let shared = SoundManager()

  func playHitmarkerSoundEffect() {
    play("Hitmarker Sound Effect by aruscio28", ext: "mp3", volume: 0.1)
  }

  func playKeypresssLoud() {
    play("Audio 01 05 Keypress from shanecutrufello", ext: "wav", volume: 2)
  }

  func playKeypresssSoft() {
    play("Audio 01 05 Keypress from shanecutrufello", ext: "wav")
  }

  func playPop3() {
    play("Pop 3 by DSG", ext: "flac")
  }

  func playPop5() {
    play("Pop 5 by DSG", ext: "flac", volume: 5)
  }

  func playPop7() {
    play("Pop 7 by DSG", ext: "flac")
  }

  func playTrumpetFanfare() {
    play("Trumpet Fanfare by Bevibeldesign", ext: "aiff")
  }

  func playWahWahSadTrombone() {
    play("Wah Wah Sad Trombone by kirbydx", ext: "wav")
  }

  func playWhoosh() {
    play("Whoosh by qubodup", ext: "flac")
  }

  private init() {}

  private var player: AVAudioPlayer?

  private func play(_ name: String, ext: String, volume: Float = 1) {
    let url =
      Bundle.module.url(forResource: name, withExtension: ext)
      ?? Bundle.module.url(forResource: name, withExtension: ext, subdirectory: "Sounds")

    guard let url else {
      print("Sound file not found: \(name).\(ext)")
#if DEBUG
      fatalError()
#else
      return
#endif
    }

    do {
      player = try AVAudioPlayer(contentsOf: url)
      player?.volume = volume
      player?.prepareToPlay()
      player?.play()
    } catch {
      print("Failed to play sound: \(error)")
    }
  }
}
