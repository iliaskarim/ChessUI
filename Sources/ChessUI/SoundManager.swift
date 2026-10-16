import AVFAudio
import ChessCore

@MainActor
final class SoundManager {
  static let shared = SoundManager()

  func playButtonPressShort() {
    play("Pop 8 by DSG", ext: "flac")
  }

  func playHitmarkerSoundEffect() {
    play("Hitmarker Sound Effect by aruscio28", ext: "mp3")
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

  func playTrumpetFanfare(delay: TimeInterval = 0) {
    play("Trumpet Fanfare by Bevibeldesign", ext: "aiff", delay: delay)
  }

  func playWahWahSadTrombone() {
    play("Wah Wah Sad Trombone by kirbydx", ext: "wav")
  }

  func playWhoosh() {
    play("Whoosh by qubodup", ext: "flac")
  }

  @discardableResult
  func playMove(_ move: Move, status: Game.Status, boardStatus: Board.Status?, isCapture: Bool) -> String {
    switch status {
    case let .winner(_, isByResignation):
      // The check tick is a short sound at the start of its file. Let it finish
      // before the fanfare, which would otherwise cover it.
      if !isByResignation {
        playHitmarkerSoundEffect()
      }
      playTrumpetFanfare(delay: isByResignation ? 0 : 0.2)
      return "trumpet"

    case .draw:
      playWahWahSadTrombone()
      return "trombone"

    case .toMove:
      if boardStatus != nil {
        playHitmarkerSoundEffect()
        return "hitmarker"
      } else if case .castling = move {
        playPop7()
        return "pop7"
      } else if isCapture {
        playPop5()
        return "pop5"
      } else {
        playPop3()
        return "pop3"
      }
    }
  }

  private init() {}

  private struct ActivePlayer {
    let player: AVAudioPlayer
    /// Device clock time when playback is scheduled to begin.
    let startsAt: TimeInterval
  }

  private var players: [ActivePlayer] = []

  private func play(_ name: String, ext: String, volume: Float = 1, delay: TimeInterval = 0) {
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

    configureSessionToMixWithOtherAudio()

    do {
      let player = try AVAudioPlayer(contentsOf: url)
      player.volume = volume
      player.prepareToPlay()
      let startsAt: TimeInterval
      if delay > 0 {
        startsAt = player.deviceCurrentTime + delay
        player.play(atTime: startsAt)
      } else {
        startsAt = player.deviceCurrentTime
        player.play()
      }
      // currentTime is 0 before a scheduled sound starts and 0 again after it
      // finishes, so it cannot tell those apart. Hold the player until the
      // device clock reaches startsAt and playback has stopped.
      let now = player.deviceCurrentTime
      players.removeAll { active in
        now >= active.startsAt && !active.player.isPlaying
      }
      players.append(ActivePlayer(player: player, startsAt: startsAt))
    } catch {
      print("Failed to play sound: \(error)")
    }
  }

  private func configureSessionToMixWithOtherAudio() {
#if os(iOS)
    let session = AVAudioSession.sharedInstance()
    let mixesWithOthers =
      session.category == .ambient || session.categoryOptions.contains(.mixWithOthers)
    guard !mixesWithOthers else { return }

    do {
      // Mix with other audio so these sounds do not pause Picture in Picture.
      try session.setCategory(.ambient, mode: .default)
      try session.setActive(true)
    } catch {
      print("Failed to configure audio session: \(error)")
    }
#endif
  }
}
