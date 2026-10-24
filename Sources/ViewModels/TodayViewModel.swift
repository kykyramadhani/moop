import Foundation
import Observation
import UIKit

@Observable
final class TodayViewModel {
    private let snaps: SnapStore

    init(snaps: SnapStore) { self.snaps = snaps }

    var today: [Snap] { snaps.snaps(on: .now) }
    var saved: Bool { !today.isEmpty }
    var latest: Snap? { today.first }
    var count: Int { today.count }
    var streak: Int { snaps.streak }

    func image(for snap: Snap) -> UIImage? { snaps.image(for: snap) }

    var dateLine: String {
        Date.now.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    // the one big line. it changes with the day rather than with the mood, so
    // the reading never reads as praise or judgement.
    var headline: String {
        saved ? "You caught today." : "An ordinary day\nstill counts."
    }

    var note: String {
        saved
            ? "\(count) moment\(count == 1 ? "" : "s")  ·  Only you can see them"
            : "A photo is enough. It doesn't need to be interesting to anyone else."
    }

    var actionTitle: String { saved ? "add another moment" : "catch a moment" }
}
