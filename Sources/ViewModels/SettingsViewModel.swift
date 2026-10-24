import Foundation
import FoundationModels
import Observation

@Observable
final class SettingsViewModel {
    private let snaps: SnapStore
    private let defaults = UserDefaults.standard

    var name: String { didSet { defaults.set(name, forKey: Prefs.name) } }
    var reminderOn: Bool { didSet { defaults.set(reminderOn, forKey: Prefs.reminderOn) } }
    var reminderHour: Int { didSet { defaults.set(reminderHour, forKey: Prefs.reminderHour) } }
    var theme: String { didSet { defaults.set(theme, forKey: Prefs.theme) } }

    var editingName = false
    var draftName = ""
    var confirmingWipe = false
    var notificationsBlocked = false
    private var queued: Date?

    init(snaps: SnapStore) {
        self.snaps = snaps
        name = defaults.string(forKey: Prefs.name) ?? "You"
        reminderOn = defaults.bool(forKey: Prefs.reminderOn)
        let hour = defaults.integer(forKey: Prefs.reminderHour)
        reminderHour = hour == 0 ? 20 : hour
        theme = defaults.string(forKey: Prefs.theme) ?? Theme.system.rawValue
    }

    var snapCount: Int { snaps.snaps.count }
    var fileURLs: [URL] { snaps.fileURLs }
    var canExport: Bool { !snaps.snaps.isEmpty }

    var availability: String {
        switch MoodEngine.availability {
        case .available: "Ready"
        case .unavailable(.modelNotReady): "Downloading"
        case .unavailable(.appleIntelligenceNotEnabled): "Off in Settings"
        case .unavailable(.deviceNotEligible): "Not supported"
        @unknown default: "Unavailable"
        }
    }

    // without this the feature looks broken on the days it is correctly silent
    var scheduleLine: String {
        if let queued {
            "Next reminder \(queued.formatted(.dateTime.weekday(.wide).hour().minute()))."
        } else {
            "Nothing queued. A reminder only goes out on an evening you have a streak to lose."
        }
    }

    var reminderTime: Date {
        Calendar.current.date(bySettingHour: reminderHour, minute: 0, second: 0, of: .now) ?? .now
    }

    var timeLabel: String {
        reminderTime.formatted(.dateTime.hour().minute())
    }

    var themeLabel: String { label(for: Theme(rawValue: theme) ?? .system) }

    func label(for option: Theme) -> String {
        switch option {
        case .system: "Follow iPhone"
        case .light: "Lilac"
        case .dark: "Night"
        }
    }

    func startEditingName() {
        draftName = name
        editingName = true
    }

    func saveName() {
        let trimmed = draftName.trimmingCharacters(in: .whitespaces)
        if !trimmed.isEmpty { name = trimmed }
    }

    // ios refuses silently once notifications are off, so ask, then say so
    func setReminder(_ wanted: Bool) async {
        reminderOn = wanted ? await ReminderScheduler.requestPermission() : false
        notificationsBlocked = wanted && !reminderOn
        reschedule()
    }

    func setReminderTime(_ date: Date) {
        reminderHour = Calendar.current.component(.hour, from: date)
        reschedule()
    }

    func refreshSchedule() async {
        queued = await ReminderScheduler.pending()
    }

    func wipe() { snaps.removeAll() }

    private func reschedule() {
        ReminderScheduler.refresh(for: snaps, at: reminderHour, enabled: reminderOn)
    }
}
