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

    func add(image: UIImage, mood: Mood?, sentence: String?, because: String? = nil) {
        let snap = Snap(id: UUID(), date: .now, mood: mood?.rawValue ?? "",
                        sentence: sentence, because: because)
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
        snaps[i] = Snap(id: snap.id, date: snap.date, mood: snap.mood,
                        sentence: sentence, because: snap.because)
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

    func snaps(inWeekOf day: Date) -> [Date] {
        let cal = Calendar.current
        guard let start = cal.dateInterval(of: .weekOfYear, for: day)?.start else { return [] }
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    func days(inMonthOf day: Date) -> [Date] {
        let cal = Calendar.current
        guard let range = cal.range(of: .day, in: .month, for: day),
              let start = cal.date(from: cal.dateComponents([.year, .month], from: day))
        else { return [] }
        return range.compactMap { cal.date(byAdding: .day, value: $0 - 1, to: start) }
    }

    func moodCounts(inMonthOf day: Date) -> [Mood: Int] {
        var counts: [Mood: Int] = [:]
        for date in days(inMonthOf: day) {
            for snap in snaps(on: date) {
                guard let mood = snap.moodCase else { continue }
                counts[mood, default: 0] += 1
            }
        }
        return counts
    }

    // one missed day does not break it. two in a row does. walking back from
    // today, a single gap is forgiven and the count carries on.
    var streak: Int {
        let cal = Calendar.current
        var day = cal.startOfDay(for: .now)
        var count = 0, gap = 0
        for _ in 0..<400 {
            if snaps(on: day).isEmpty {
                gap += 1
                if gap >= 2 { break }
            } else {
                count += 1
                gap = 0
            }
            guard let back = cal.date(byAdding: .day, value: -1, to: day) else { break }
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
