import FoundationModels
import ImageIO
import UIKit

struct MoodReading {
    let mood: Mood
    let sentence: String
    /// what in the photo pointed at that mood. shown on the explanation screen.
    let because: String
}

@Generable
struct MoodCall {
    let mood: Mood

    @Guide(description: "One short clause naming what in the photo suggested that mood. Under twelve words. No second person, no advice.")
    let because: String
}

enum MoodError: LocalizedError {
    case unreadablePhoto
    var errorDescription: String? { "That photo could not be read." }
}

enum MoodEngine {

    static var availability: SystemLanguageModel.Availability {
        SystemLanguageModel.default.availability
    }

    // without the five definitions every photo comes back as the same mood
    static let instructions = """
    You judge the mood of a photo.
    calm is quiet, still, nature at rest. adventure is travel, height, open road, motion. \
    homey is indoors, food, drink, warm domestic things. playful is pets, toys, games, colour. \
    mystery is when the photo is too thin or too mixed to read.
    """

    static let sentencePrompt = """
    Now write ONE casual sentence under 20 words about this photo, the way someone jots a moment \
    down in a mood tracker. Describe the place, the light and the mood of it. Tone example: \
    "A good drinks and food in a cozy cafe is never wrong." No advice, no affirmation, no second \
    person. Sentence only.
    """

    static func read(_ image: UIImage) async throws -> MoodReading {
        guard let cgImage = image.cgImage else { throw MoodError.unreadablePhoto }

        // library photos carry orientation in metadata, and without it a portrait
        // shot reaches the model sideways
        let photo = Attachment(cgImage, orientation: image.cgOrientation).label("the photo")
        let session = LanguageModelSession(instructions: instructions)

        // greedy, so one photo always gives the same mood and the same reason
        let call = try await session.respond(
            to: Prompt {
                "Which mood fits this photo best, and what in it says so?"
                photo
            },
            generating: MoodCall.self,
            options: GenerationOptions(samplingMode: .greedy)
        ).content

        // attach the photo again so the sentence comes from the image, not from the
        // mood just picked. default sampling, so the wording varies between runs.
        let sentence = try await session.respond(
            to: Prompt {
                sentencePrompt
                photo
            }
        ).content.trimmingCharacters(in: .whitespacesAndNewlines)

        print("[moop] mood: \(call.mood.rawValue) because \(call.because)")
        print("[moop] sentence: \(sentence)")
        return MoodReading(mood: call.mood, sentence: sentence, because: call.because)
    }
}

extension MoodEngine {
    // one turn only, for the Reword action
    static func sentence(for image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else { throw MoodError.unreadablePhoto }
        let photo = Attachment(cgImage, orientation: image.cgOrientation).label("the photo")
        let session = LanguageModelSession(instructions: instructions)
        return try await session.respond(
            to: Prompt {
                sentencePrompt
                photo
            }
        ).content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

#if DEBUG
extension MoodEngine {
    static func probe() async {
        print("[moop] availability: \(SystemLanguageModel.default.availability)")
        guard case .available = SystemLanguageModel.default.availability else {
            print("[moop] PROBE SKIPPED — apple intelligence not available")
            return
        }
        do {
            let text = try await LanguageModelSession().respond(to: "Say hello in three words.").content
            print("[moop] PROBE OK — \(text)")
        } catch {
            print("[moop] PROBE FAILED — \(error)")
            return
        }
        await probeImage()
    }

    // end to end check of the image path: drop a jpeg at Documents/probe.jpg
    static func probeImage() async {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("probe.jpg")
        guard let image = UIImage(contentsOfFile: url.path) else {
            print("[moop] no probe.jpg, skipping image probe")
            return
        }
        do {
            let reading = try await read(image)
            print("[moop] IMAGE PROBE OK — \(reading.mood.rawValue) / \(reading.sentence)")
            print("[moop] because — \(reading.because)")
        } catch {
            print("[moop] IMAGE PROBE FAILED — \(error)")
        }
    }
}
#endif
