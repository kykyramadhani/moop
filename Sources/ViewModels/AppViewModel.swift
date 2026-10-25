import Observation

@Observable
final class AppViewModel {
    let snaps = SnapStore()
    let reader = MoodReader()

    var tab: Tab = .today
    var todayPath: [TodayRoute] = []
    var historyPath: [HistoryRoute] = []
    var showingCamera = false
    var showingSplash = true

    func splashFinished() { showingSplash = false }
    func openCamera() { showingCamera = true }

    // the camera is a cover over Today. when the read lands, the cover closes
    // and Today pushes the result, which is where the design puts it.
    func cameraFinished(read: Bool) {
        showingCamera = false
        if read { todayPath = [.result] }
    }

    func backToToday() { todayPath.removeAll() }

    // removeLast on an empty path would trap, and a back button can always be
    // hit twice before the push animation lands.
    func popToday() { if !todayPath.isEmpty { todayPath.removeLast() } }
    func popHistory() { if !historyPath.isEmpty { historyPath.removeLast() } }

    func armReminder(hour: Int, enabled: Bool) {
        ReminderScheduler.refresh(for: snaps, at: hour, enabled: enabled)
    }
}
