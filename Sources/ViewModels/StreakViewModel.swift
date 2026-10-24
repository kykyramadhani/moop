import Foundation
import Observation

@Observable
final class StreakViewModel {
    struct Day: Identifiable {
        let id: Date
        let letter: String
        let saved: Bool
        let isToday: Bool
    }

    private let snaps: SnapStore
    private let cal = Calendar.current

    init(snaps: SnapStore) { self.snaps = snaps }

    var count: Int { snaps.streak }

    var headline: String { "Keep the feeling.\nLose the pressure." }

    var reassurance: String {
        count == 0 ? "Nothing to lose yet." : "One quiet day is okay."
    }

    // the seven days ending today, so the dots always finish on the one the
    // person is living in
    var week: [Day] {
        let today = cal.startOfDay(for: .now)
        return (0..<7).reversed().compactMap { back in
            guard let date = cal.date(byAdding: .day, value: -back, to: today) else { return nil }
            let letter = date.formatted(.dateTime.weekday(.narrow))
            return Day(id: date, letter: letter,
                       saved: !snaps.snaps(on: date).isEmpty,
                       isToday: back == 0)
        }
    }
}
