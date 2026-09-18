import Observation
import UIKit

@Observable
final class DayViewModel {
    let day: Date
    private let snaps: SnapStore

    var index = 0
    var confirmingDelete = false
    private(set) var dismissed = false

    init(day: Date, snaps: SnapStore) {
        self.day = day
        self.snaps = snaps
    }

    var shots: [Snap] { snaps.snaps(on: day) }
    var showsDots: Bool { shots.count > 1 }

    var current: Snap? {
        let shots = shots
        return shots.indices.contains(index) ? shots[index] : shots.first
    }

    func image(for snap: Snap) -> UIImage? { snaps.image(for: snap) }

    var dateLine: String {
        guard let current else { return "" }
        let stamp = current.date
            .formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
            .uppercased()
        return shots.count > 1 ? "\(stamp)  ·  \(index + 1) OF \(shots.count)" : stamp
    }

    func delete() {
        guard let current else { return }
        snaps.remove(current)
        if shots.isEmpty { dismissed = true } else { index = min(index, shots.count - 1) }
    }
}
