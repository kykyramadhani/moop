import Foundation

struct Snap: Codable, Identifiable {
    let id: UUID
    let date: Date
    let mood: String
    let sentence: String?

    var moodCase: Mood { Mood(rawValue: mood) ?? .mystery }

    // index.json on phones that already ran moop spells this "vibe". renaming
    // the key would decode to nil and wipe the whole calendar.
    enum CodingKeys: String, CodingKey {
        case id, date, sentence
        case mood = "vibe"
    }
}
