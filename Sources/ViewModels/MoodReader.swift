import FoundationModels
import Observation
import UIKit

@Observable
final class MoodReader {

    enum Phase {
        case idle
        case working
        case result(Mood, String, UIImage)
        case failed(String)
        case unavailable(Block)
    }

    private(set) var phase: Phase = .idle
    // kept so a failed read can be tried again on the same photo
    private(set) var lastPhoto: UIImage?

    var isWorking: Bool { if case .working = phase { true } else { false } }
    var isFailed: Bool { if case .failed = phase { true } else { false } }

    var result: (mood: Mood, sentence: String, photo: UIImage)? {
        if case let .result(mood, sentence, photo) = phase { (mood, sentence, photo) } else { nil }
    }

    var block: Block? {
        if case let .unavailable(block) = phase { block } else { nil }
    }

    var failure: String? {
        if case let .failed(why) = phase { why } else { nil }
    }

    // only a failed read is worth retrying. a missing model is explained instead,
    // so the shutter stays dim and a tap opens the alert.
    var canRetry: Bool {
        guard lastPhoto != nil, case .failed = phase else { return false }
        return true
    }

    func reset() { phase = .idle }

    func checkAvailability() {
        switch MoodEngine.availability {
        case .available:
            if case .unavailable = phase { phase = .idle }
        case .unavailable(let reason):
            phase = .unavailable(Self.describe(reason))
        @unknown default:
            phase = .unavailable(Block(title: "Apple Intelligence is not available",
                                       message: "moop cannot read your picture right now.",
                                       canOpenSettings: false))
        }
    }

    func read(_ image: UIImage) async {
        lastPhoto = image
        phase = .working
        do {
            let reading = try await MoodEngine.read(image)
            phase = .result(reading.mood, reading.sentence, image)
        } catch {
            print("[moop] failed: \(error)")
            phase = .failed(error.localizedDescription)
        }
    }

    func retry() async {
        guard let lastPhoto else { return }
        await read(lastPhoto)
    }

    // greedy sampling fixes the mood to the photo, so only the wording can change
    func reword() async -> String? {
        guard case let .result(mood, _, photo) = phase else { return nil }
        guard let fresh = try? await MoodEngine.sentence(for: photo) else { return nil }
        phase = .result(mood, fresh, photo)
        return fresh
    }

    private static func describe(_ reason: SystemLanguageModel.Availability.UnavailableReason) -> Block {
        switch reason {
        case .deviceNotEligible:
            Block(title: "Not supported on this iPhone",
                  message: "moop needs Apple Intelligence to read a moop, and this iPhone cannot run it.",
                  canOpenSettings: false)
        case .appleIntelligenceNotEnabled:
            Block(title: "Turn on Apple Intelligence",
                  message: "Apple Intelligence reads your photo on this iPhone. Switch it on in Settings to read a moop.",
                  canOpenSettings: true)
        case .modelNotReady:
            Block(title: "Apple Intelligence is downloading",
                  message: "It finishes on its own. Try the shutter again in a little while.",
                  canOpenSettings: false)
        @unknown default:
            Block(title: "Apple Intelligence is not available",
                  message: "moop cannot read a moop right now.",
                  canOpenSettings: false)
        }
    }
}
