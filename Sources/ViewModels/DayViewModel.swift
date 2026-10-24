import Foundation
import Observation
import UIKit

@Observable
final class DayViewModel {
    let day: Date
    private let snaps: SnapStore

    /// which snap sits in the hero slot. the rest line up underneath.
    var focused = 0
    var confirmingDelete = false
    private(set) var dismissed = false

    init(day: Date, snaps: SnapStore) {
        self.day = day
        self.snaps = snaps
    }

    var shots: [Snap] { snaps.snaps(on: day) }

    var hero: Snap? {
        let shots = shots
        return shots.indices.contains(focused) ? shots[focused] : shots.first
    }

    var rest: [Snap] {
        guard let hero else { return [] }
        return shots.filter { $0.id != hero.id }
    }

    var title: String {
        day.formatted(.dateTime.weekday(.wide)) + ",\n" + day.formatted(.dateTime.day().month(.wide))
    }

    var countLabel: String {
        let n = shots.count
        return "\(n) MOMENT\(n == 1 ? "" : "S")"
    }

    func time(of snap: Snap) -> String {
        snap.date.formatted(.dateTime.hour().minute())
    }

    func image(for snap: Snap) -> UIImage? { snaps.image(for: snap) }

    func focus(_ snap: Snap) {
        guard let i = shots.firstIndex(where: { $0.id == snap.id }) else { return }
        focused = i
    }

    func delete() {
        guard let hero else { return }
        snaps.remove(hero)
        if shots.isEmpty { dismissed = true } else { focused = min(focused, shots.count - 1) }
    }
}
