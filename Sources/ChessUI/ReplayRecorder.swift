import AVFAudio
import Foundation

/// Writes the replay's move sounds into one file as they play.
///
/// The simulator recorder has no audio track, so the capture mixes this file
/// back onto the movie. Sample 0 is ``startedAt``.
@MainActor
final class ReplayRecorder {
  static let shared = ReplayRecorder()

  private(set) var isRecording = false

  private let sampleRate = 44100.0

  private var startedAt: Date?

  private var left: [Float] = []

  private var right: [Float] = []

  private init() {}

  func start() {
    guard !isRecording else {
      return
    }

    left = []
    right = []
    let startedAt = Date()
    self.startedAt = startedAt
    isRecording = true

    let stamp = documents.appendingPathComponent("replay-audio-start")
    let text = String(format: "%.6f\n", startedAt.timeIntervalSince1970)
    try? text.write(to: stamp, atomically: true, encoding: .utf8)
  }

  func mix(url: URL, volume: Float, delay: TimeInterval = 0) {
    guard isRecording, let startedAt, let samples = samples(from: url) else {
      return
    }

    let gain = min(max(volume, 0), 1)
    let elapsed = Date().timeIntervalSince(startedAt) + delay
    let start = Int((elapsed * sampleRate).rounded())
    let end = start + samples.left.count
    if left.count < end {
      let gap = end - left.count
      left.append(contentsOf: repeatElement(0, count: gap))
      right.append(contentsOf: repeatElement(0, count: gap))
    }

    for index in samples.left.indices {
      left[start + index] += samples.left[index] * gain
      right[start + index] += samples.right[index] * gain
    }
  }

  func stop() {
    guard isRecording, let startedAt else {
      return
    }

    isRecording = false
    let url = documents.appendingPathComponent("replay-audio.caf")
    try? FileManager.default.removeItem(at: url)
    defer {
      left = []
      right = []
      self.startedAt = nil
    }

    guard !left.isEmpty,
          let format = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 2,
            interleaved: false
          ),
          let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(left.count)),
          let channels = buffer.floatChannelData else {
      print("Replay audio was empty (started \(startedAt)).")
      return
    }

    buffer.frameLength = AVAudioFrameCount(left.count)
    for index in left.indices {
      channels[0][index] = min(max(left[index], -1), 1)
      channels[1][index] = min(max(right[index], -1), 1)
    }

    do {
      let file = try AVAudioFile(forWriting: url, settings: format.settings)
      try file.write(from: buffer)
    } catch {
      print("Failed to write replay audio: \(error)")
    }
  }

  private var documents: URL {
    FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
  }

  private func samples(from url: URL) -> (left: [Float], right: [Float])? {
    guard let file = try? AVAudioFile(forReading: url),
          let buffer = AVAudioPCMBuffer(
            pcmFormat: file.processingFormat,
            frameCapacity: AVAudioFrameCount(file.length)
          ) else {
      return nil
    }

    do {
      try file.read(into: buffer)
    } catch {
      return nil
    }

    guard let rendered = render(buffer, rate: sampleRate), let channels = rendered.floatChannelData else {
      return nil
    }

    let count = Int(rendered.frameLength)
    let left = Array(UnsafeBufferPointer(start: channels[0], count: count))
    let right = rendered.format.channelCount > 1
      ? Array(UnsafeBufferPointer(start: channels[1], count: count))
      : left
    return (left, right)
  }

  private func render(_ buffer: AVAudioPCMBuffer, rate: Double) -> AVAudioPCMBuffer? {
    let source = buffer.format
    guard source.sampleRate != rate || source.commonFormat != .pcmFormatFloat32 else {
      return buffer
    }

    guard let target = AVAudioFormat(
      commonFormat: .pcmFormatFloat32,
      sampleRate: rate,
      channels: source.channelCount,
      interleaved: false
    ), let converter = AVAudioConverter(from: source, to: target) else {
      return nil
    }

    let frames = Double(buffer.frameLength) * rate / source.sampleRate
    let capacity = AVAudioFrameCount(frames.rounded(.up)) + 32
    guard let output = AVAudioPCMBuffer(pcmFormat: target, frameCapacity: capacity) else {
      return nil
    }

    var supplied = false
    var error: NSError?
    converter.convert(to: output, error: &error) { _, status in
      if supplied {
        status.pointee = .endOfStream
        return nil
      }

      supplied = true
      status.pointee = .haveData
      return buffer
    }
    guard error == nil, output.frameLength > 0 else {
      return nil
    }

    return output
  }
}
