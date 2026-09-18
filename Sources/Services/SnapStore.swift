import Foundation
import UIKit

// a snap is a jpeg on disk plus a row in an index file. no database needed for
// a calendar of a few hundred entries.
@Observable
final class SnapStore {
    private(set) var snaps: [Snap] = []

    private let folder: URL = {
        let base = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("snaps", isDirectory: true)
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        return base
    }()
    private var indexURL: URL { folder.appendingPathComponent("index.json") }

    init() { load() }

    func image(for snap: Snap) -> UIImage? {
        UIImage(contentsOfFile: folder.appendingPathComponent("\(snap.id).jpg").path)
    }

    func add(image: UIImage, mood: Mood, sentence: String?) {
        let snap = Snap(id: UUID(), date: .now, mood: mood.rawValue, sentence: sentence)
        if let data = image.jpegData(compressionQuality: 0.9) {
            try? data.write(to: folder.appendingPathComponent("\(snap.id).jpg"))
        }
        snaps.insert(snap, at: 0)
        save()
    }

    // newest first, because the calendar cell shows the latest one
    func snaps(on day: Date) -> [Snap] {
        snaps.filter { Calendar.current.isDate($0.date, inSameDayAs: day) }
    }

    var fileURLs: [URL] {
        snaps.map { folder.appendingPathComponent("\($0.id).jpg") }
            .filter { FileManager.default.fileExists(atPath: $0.path) }
    }

    func reword(_ snap: Snap, to sentence: String) {
        guard let i = snaps.firstIndex(where: { $0.id == snap.id }) else { return }
        snaps[i] = Snap(id: snap.id, date: snap.date, mood: snap.mood, sentence: sentence)
        save()
    }

    func remove(_ snap: Snap) {
        try? FileManager.default.removeItem(at: folder.appendingPathComponent("\(snap.id).jpg"))
        snaps.removeAll { $0.id == snap.id }
        save()
    }

    func removeAll() {
        for snap in snaps {
            try? FileManager.default.removeItem(at: folder.appendingPathComponent("\(snap.id).jpg"))
        }
        snaps.removeAll()
        save()
    }

    // consecutive days ending today or yesterday
    var streak: Int {
        let calendar = Calendar.current
        var day = calendar.startOfDay(for: .now)
        if snaps(on: day).isEmpty {
            guard let back = calendar.date(byAdding: .day, value: -1, to: day) else { return 0 }
            day = back
        }
        var count = 0
        while !snaps(on: day).isEmpty {
            count += 1
            guard let back = calendar.date(byAdding: .day, value: -1, to: day) else { break }
            day = back
        }
        return count
    }

    private func load() {
        guard let data = try? Data(contentsOf: indexURL),
              let rows = try? JSONDecoder().decode([Snap].self, from: data) else { return }
        snaps = rows.sorted { $0.date > $1.date }
    }

    private func save() {
        guard let data = try? JSONEncoder().encode(snaps) else { return }
        try? data.write(to: indexURL)
    }
}
