import Observation

@Observable
final class AppViewModel {
    let snaps = SnapStore()
    let reader = MoodReader()
    let navigator = Navigator()

    var showingSplash = true

    func splashFinished() { showingSplash = false }

    // the trigger is one-shot on purpose, so something has to re-arm it. a new
    // snap is not enough: the app can sit unopened for days, and once the shot
    // has fired nothing else would ever queue the next.
    func armReminder(hour: Int, enabled: Bool) {
        ReminderScheduler.refresh(for: snaps, at: hour, enabled: enabled)
    }
}
