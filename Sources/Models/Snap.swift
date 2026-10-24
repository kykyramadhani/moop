import Foundation

struct Snap: Codable, Identifiable {
    let id: UUID
    let date: Date
    /// empty when the photo was kept without a reading
    let mood: String
    let sentence: String?
    /// what the reader saw. nil on snaps saved before this existed.
    let because: String?

    var moodCase: Mood? { Mood(rawValue: mood) }
    var isLabelled: Bool { moodCase != nil }

    // index.json on phones that already ran moop spells this "vibe". renaming
    // the key would decode to nil and wipe the whole calendar.
    enum CodingKeys: String, CodingKey {
        case id, date, sentence, because
        case mood = "vibe"
    }
}
