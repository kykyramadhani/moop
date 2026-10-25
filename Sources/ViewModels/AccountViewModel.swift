import AuthenticationServices
import Foundation
import Observation

// who the moments belong to and where they live. the views only read this and
// call it: choosing a mode, signing in, turning sync on and off, backing up,
// restoring and deleting all pass through here.
@Observable
final class AccountViewModel {
    enum Step { case choice, checking, ready, unavailable }

    struct Notice: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    let snaps: SnapStore
    let cloud: CloudSync
    private let defaults = UserDefaults.standard

    private(set) var mode: StorageMode
    private(set) var syncEnabled: Bool
    private(set) var auth: AuthState
    private(set) var availability: CloudAvailability = .unknown
    /// false only for a person who has not met the storage choice yet
    private(set) var chosen: Bool
    private(set) var busy = false

    var step: Step = .choice
    var notice: Notice?

    var confirmingEnable = false
    var confirmingStop = false
    var confirmingBackup = false
    var confirmingWipe = false
    var confirmingWipeCloud = false
    var showingExporter = false
    var showingImporter = false
    private(set) var exportFile: URL?
    var restoreJob: RestoreJob?

    init(snaps: SnapStore) {
        self.snaps = snaps
        cloud = CloudSync(snaps: snaps)

        // someone who already uses moop has been on this iPhone the whole time.
        // they land in local mode, with every moment where it was.
        let saved = defaults.string(forKey: Prefs.storageMode).flatMap(StorageMode.init)
        let existing = defaults.bool(forKey: Prefs.onboarded)
        let mode = saved ?? .localOnly
        if saved == nil && existing { defaults.set(mode.rawValue, forKey: Prefs.storageMode) }
        self.mode = mode
        chosen = saved != nil || existing
        syncEnabled = defaults.bool(forKey: Prefs.syncEnabled) && mode == .appleCloud
        auth = Keychain.appleUser == nil ? .guest : .appleSignedIn

        cloud.onEnded = { [weak self] in self?.setSync(false) }
        if syncEnabled && auth == .appleSignedIn { cloud.start() }
    }

    // MARK: reading state

    var syncLabel: String {
        guard syncEnabled else { return "Off" }
        if auth == .reauthRequired { return "Sign in needs attention" }
        if availability != .available && availability != .unknown { return "iCloud unavailable" }
        return cloud.state.label
    }

    var lastSyncedLabel: String? {
        guard syncEnabled, let date = cloud.lastSynced else { return nil }
        return date.formatted(.relative(presentation: .named))
    }

    // what to do about it, said for the state it is really in
    var help: String? {
        guard syncEnabled else { return nil }
        if auth == .reauthRequired { return "Your Apple sign-in was changed or removed. Moments stay on this iPhone. Sign in again to resume syncing." }
        if availability != .available && availability != .unknown { return availability.explanation }
        switch cloud.state {
        case .offline: return "Your moments are safe on this iPhone and will sync when you are back online."
        case .full: return "iCloud is out of space. Free some up, then try again. Nothing was removed from this iPhone."
        case .attention: return "Something went wrong. Your moments are still on this iPhone."
        default: return nil
        }
    }

    var canRetry: Bool { syncEnabled && [.offline, .full, .attention, .unavailable].contains(cloud.state) }
    var tagline: String {
        mode == .localOnly
            ? "No account. No feed. Stored on this iPhone."
            : "No feed. Stored on this iPhone, and in your private iCloud if sync is on."
    }

    // MARK: onboarding and mode

    func chooseLocal() {
        setMode(.localOnly)
        chosen = true
    }

    func finishOnboarding() { chosen = true }

    func handleApple(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .success(let done):
            guard let credential = done.credential as? ASAuthorizationAppleIDCredential else { return }
            Keychain.appleUser = credential.user
            auth = .appleSignedIn
            setMode(.appleCloud)
            step = .checking
            availability = await CloudSync.availability()
            if chosen {
                if availability == .available { confirmingEnable = true } else { notice = unavailableNotice }
            } else {
                step = availability == .available ? .ready : .unavailable
            }
        case .failure(let error):
            step = .choice
            // closing the sheet is a choice, not a failure
            if (error as? ASAuthorizationError)?.code != .canceled {
                notice = Notice(title: "Sign in did not finish",
                                message: "Nothing was changed. You can try again, or continue without an account.")
            }
        }
    }

    func enableFromOnboarding() {
        setSync(true)
        chosen = true
    }

    // MARK: sync

    func refresh() async {
        if let user = Keychain.appleUser {
            let state = try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: user)
            switch state {
            case .authorized: auth = .appleSignedIn
            case .revoked, .notFound:
                // the sign-in is gone. the moments are not, and stay put.
                auth = .reauthRequired
                cloud.stop()
            default: break
            }
        }
        availability = await CloudSync.availability()
        if syncEnabled && auth == .appleSignedIn && availability == .available { cloud.start() }
    }

    func requestEnable() async {
        availability = await CloudSync.availability()
        if availability == .available { confirmingEnable = true } else { notice = unavailableNotice }
    }

    func confirmEnable() { setSync(true) }
    func retry() { cloud.retry() }
    func stopSyncing() { setSync(false) }

    func useWithoutAccount() {
        setSync(false)
        Keychain.appleUser = nil
        auth = .guest
        setMode(.localOnly)
    }

    var enableTitle: String { "Move \(snaps.snaps.count) \(snaps.snaps.count == 1 ? "moment" : "moments") into private iCloud?" }

    private var unavailableNotice: Notice {
        Notice(title: "iCloud is not available", message: availability.explanation + " Your moments stay on this iPhone.")
    }

    private func setMode(_ new: StorageMode) {
        mode = new
        defaults.set(new.rawValue, forKey: Prefs.storageMode)
    }

    private func setSync(_ on: Bool) {
        syncEnabled = on
        defaults.set(on, forKey: Prefs.syncEnabled)
        if on { cloud.start() } else { cloud.stop() }
    }

    // MARK: backup and restore

    func askBackup() { confirmingBackup = true }

    func makeBackup() async {
        busy = true
        defer { busy = false }
        do {
            let (name, theme) = (defaults.string(forKey: Prefs.name), defaults.string(forKey: Prefs.theme))
            exportFile = try await Task.detached { [snaps] in
                try BackupService.make(from: snaps, name: name, theme: theme)
            }.value
            // a picker asked for while the alert is still closing is dropped
            try? await Task.sleep(for: .milliseconds(400))
            showingExporter = true
        } catch {
            notice = Notice(title: "Backup not saved", message: error.localizedDescription)
        }
    }

    // closing the Files picker is not a backup, and says nothing
    func exported(_ result: Result<URL, Error>) {
        if let exportFile { try? FileManager.default.removeItem(at: exportFile) }
        exportFile = nil
        switch result {
        case .success:
            notice = Notice(title: "Backup saved",
                            message: "Keep it somewhere safe. Anyone with this file may be able to see your moments.")
        case .failure(let error):
            if (error as? CocoaError)?.code != .userCancelled {
                notice = Notice(title: "Backup not saved", message: error.localizedDescription)
            }
        }
    }

    func restore(from result: Result<URL, Error>) async {
        guard case .success(let url) = result else { return }
        busy = true
        defer { busy = false }
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            restoreJob = try await Task.detached { try BackupService.open(url) }.value
        } catch {
            notice = Notice(title: "Nothing was restored", message: error.localizedDescription)
        }
    }

    var restoreTitle: String {
        guard let job = restoreJob else { return "" }
        return "Merge \(job.newCount(in: snaps)) new \(job.newCount(in: snaps) == 1 ? "moment" : "moments")?"
    }

    var restoreMessage: String {
        guard let job = restoreJob else { return "" }
        let have = job.rows.count - job.newCount(in: snaps)
        return "The backup holds \(job.rows.count). \(have) already here. Nothing already here is changed."
    }

    func confirmRestore() {
        guard let job = restoreJob else { return }
        let fresh = snaps.snaps.isEmpty
        let before = Set(snaps.snaps.map(\.id))
        snaps.merge(job.rows, photos: job.photos)
        if syncEnabled { cloud.queue(job.rows.map(\.id).filter { !before.contains($0) }) }
        // a new phone gets its name and theme back, a lived-in one keeps its own
        if fresh {
            if let name = job.manifest.name { defaults.set(name, forKey: Prefs.name) }
            if let theme = job.manifest.theme { defaults.set(theme, forKey: Prefs.theme) }
        }
        job.discard()
        restoreJob = nil
    }

    func cancelRestore() {
        restoreJob?.discard()
        restoreJob = nil
    }

    // MARK: delete

    func requestWipe() {
        if syncEnabled { confirmingWipeCloud = true } else { confirmingWipe = true }
    }

    func wipeLocal() { snaps.wipeLocal() }

    // keeps iCloud as it is and stops syncing, so the next sync cannot quietly
    // bring everything back
    func wipeThisPhoneOnly() {
        setSync(false)
        snaps.wipeLocal()
    }

    func wipeEverywhere() { cloud.deleteEverywhere() }
}
