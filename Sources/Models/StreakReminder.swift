import Foundation

struct StreakReminder {
    let days: Int

    var message: String { "Your \(days) days are safe until midnight." }
    static let title = "Still time for today"

    // takes the three facts it needs rather than the whole store, so it can be
    // checked without a disk full of snaps and a clock set to 8pm
    static func due(streak: Int, snappedToday: Bool, at now: Date = .now) -> StreakReminder? {
        guard streak >= 2, !snappedToday,
              Calendar.current.component(.hour, from: now) >= 19
        else { return nil }
        return StreakReminder(days: streak)
    }
}

#if DEBUG
extension StreakReminder {
    // four guards and no ui, so it can be quietly wrong for weeks. runs at launch.
    static func check() {
        let cal = Calendar.current
        let evening = cal.date(bySettingHour: 20, minute: 0, second: 0, of: .now)!
        let noon = cal.date(bySettingHour: 12, minute: 0, second: 0, of: .now)!
        assert(due(streak: 4, snappedToday: false, at: evening)?.days == 4)
        assert(due(streak: 4, snappedToday: false, at: evening)?.message
               == "Your 4 days are safe until midnight.")
        assert(due(streak: 4, snappedToday: true, at: evening) == nil, "already snapped today")
        assert(due(streak: 1, snappedToday: false, at: evening) == nil, "one day is no streak to lose")
        assert(due(streak: 0, snappedToday: false, at: evening) == nil, "no streak at all")
        assert(due(streak: 4, snappedToday: false, at: noon) == nil, "too early to speak up")
        print("[moop] streak rules OK")
    }
}
#endif
