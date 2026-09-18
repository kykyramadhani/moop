import Foundation
import UserNotifications

// ios cannot skip a day on a repeating trigger, so only one shot is ever queued
// and something has to queue the next one.
enum ReminderScheduler {
    private static let id = "moop.streak"

    static func requestPermission() async -> Bool {
        (try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound])) ?? false
    }

    // what is actually queued with ios, so settings can say so instead of the
    // feature being invisible until the evening it matters
    static func pending() async -> Date? {
        await UNUserNotificationCenter.current().pendingNotificationRequests()
            .first { $0.identifier == id }
            .flatMap { ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate() }
    }

    static func refresh(for store: SnapStore, at hour: Int, enabled: Bool) {
        let centre = UNUserNotificationCenter.current()
        centre.removeAllPendingNotificationRequests()
        guard enabled, store.streak >= 1 else { return }

        let calendar = Calendar.current
        var fire = calendar.date(bySettingHour: hour, minute: 0, second: 0, of: .now) ?? .now
        // nothing to say tonight if today is already done, or the hour has passed
        if !store.snaps(on: .now).isEmpty || fire <= .now {
            fire = calendar.date(byAdding: .day, value: 1, to: fire) ?? fire
        }

        let content = UNMutableNotificationContent()
        content.title = StreakReminder.title
        content.body = StreakReminder(days: max(store.streak, 1)).message
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: fire),
            repeats: false)
        centre.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
    }
}
