import AVFAudio
import Foundation
import TalkifyCore
import os

/// A Direct Dictation session's audio as Breeze wants it: 16 kHz mono floats,
/// kept beside the buffers Apple Speech is fed. The microphone's audio thread
/// appends; the session takes the lot when it finishes.
final class BreezeRecording: @unchecked Sendable {
  static let format = AVAudioFormat(
    commonFormat: .pcmFormatFloat32,
    sampleRate: 16_000,
    channels: 1,
    interleaved: false
  )

  private let lock = NSLock()
  private var samples: [Float] = []

  func append(_ buffer: AVAudioPCMBuffer) {
    guard let channel = buffer.floatChannelData?[0] else { return }
    let heard = UnsafeBufferPointer(start: channel, count: Int(buffer.frameLength))
    lock.withLock { samples.append(contentsOf: heard) }
  }

  func take() -> [Float] {
    lock.withLock {
      let taken = samples
      samples = []
      return taken
    }
  }
}

/// Breeze ASR 25, the Speech Model the Linux Talkify uses for Taiwanese
/// Mandarin with English mixed in, through the same library, so both write
/// the same text: its words, the Tidy pass (spoken punctuation, "刪掉") and
/// the Vocabulary.
///
/// Apple Speech still draws the live draft, which it does in a tenth of a
/// second; Breeze hears the finished recording again and its text is what
/// lands. Apple Speech writes "deploy" as "thepoy" inside a Mandarin
/// sentence, and Breeze does not.
///
/// Optional by design: without the model file every session is Apple's alone.
actor BreezeSpeechModel {
  static let shared = BreezeSpeechModel()

  /// Where the Linux Talkify keeps the model and the words file, so a
  /// machine set up for one needs nothing more for the other.
  static let weights = FileManager.default.homeDirectoryForCurrentUser
    .appending(path: ".local/share/talkify/models/breeze-asr-25-q5_k/ggml-model-q5_k.bin")
  static let vocabulary = FileManager.default.homeDirectoryForCurrentUser
    .appending(path: ".config/talkify/words.txt")

  static var isInstalled: Bool {
    FileManager.default.fileExists(atPath: weights.path)
  }

  /// Breeze was tuned on Mandarin. Any other language is Apple's.
  static func hears(_ locale: Locale) -> Bool {
    isInstalled && locale.language.languageCode?.identifier == "zh"
  }

  private static let logger = Logger(subsystem: "com.unayung.TalkifyTW", category: "breeze")

  private var speech: OpaquePointer?
  private var failedToLoad = false

  /// Loading takes a second, and the first time on a machine several more
  /// while Metal compiles its shaders, so it is done when a Mandarin trigger
  /// is prewarmed rather than on the first release.
  func load() {
    guard speech == nil, !failedToLoad, Self.isInstalled else { return }
    let started = ContinuousClock.now
    speech = talkify_open(Self.weights.path)
    failedToLoad = speech == nil
    if failedToLoad {
      Self.logger.error("could not load \(Self.weights.path, privacy: .public)")
    } else {
      Self.logger.info("loaded in \(ContinuousClock.now - started, privacy: .public)")
    }
  }

  /// The finished recording's text, or nil when Breeze has none to offer and
  /// Apple's stands.
  func dictate(_ samples: [Float]) -> String? {
    load()
    guard let speech, !samples.isEmpty else { return nil }
    let started = ContinuousClock.now
    let words = try? String(contentsOf: Self.vocabulary, encoding: .utf8)
    let answer = samples.withUnsafeBufferPointer { heard in
      talkify_dictate(speech, heard.baseAddress, heard.count, words, nil)
    }
    guard let answer else { return nil }
    defer { talkify_free(answer) }

    struct Dictated: Decodable {
      let text: String
    }
    let dictated = try? JSONDecoder().decode(Dictated.self, from: Data(String(cString: answer).utf8))
    let seconds = Double(samples.count) / 16_000
    Self.logger.info(
      "\(seconds, format: .fixed(precision: 1), privacy: .public) s heard in \(ContinuousClock.now - started, privacy: .public)"
    )
    guard let text = dictated?.text, !text.isEmpty else { return nil }
    return text
  }
}
