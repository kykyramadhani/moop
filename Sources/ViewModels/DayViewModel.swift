import Foundation
import Observation
import UIKit

@Observable
final class DayViewModel {
    let day: Date
    private let snaps: SnapStore

    /// the snap the delete alert is asking about
    var pendingDelete: Snap?
    private(set) var dismissed = false

    init(day: Date, snaps: SnapStore) {
        self.day = day
        self.snaps = snaps
    }

    /// newest first, so the last thing you saved is the first thing you see
    var shots: [Snap] { snaps.snaps(on: day).sorted { $0.date > $1.date } }
    var isEmpty: Bool { shots.isEmpty }

    var title: String {
        day.formatted(.dateTime.weekday(.wide)) + ",\n" + day.formatted(.dateTime.day().month(.wide))
    }

    var countLabel: String {
        let n = shots.count
        return "\(n) MOMENT\(n == 1 ? "" : "S")"
    }

    var confirmingDelete: Bool {
        get { pendingDelete != nil }
        set { if !newValue { pendingDelete = nil } }
    }

    func time(of snap: Snap) -> String { snap.date.formatted(.dateTime.hour().minute()) }

    func mood(of snap: Snap) -> String { snap.moodCase?.rawValue ?? "kept without a word" }

    func image(for snap: Snap) -> UIImage? { snaps.image(for: snap) }

    func ask(_ snap: Snap) { pendingDelete = snap }

    func delete() {
        guard let snap = pendingDelete else { return }
        snaps.remove(snap)
        pendingDelete = nil
        if shots.isEmpty { dismissed = true }
    }
}
