import AuthenticationServices
import SwiftUI
import UniformTypeIdentifiers

struct SettingsView: View {
    @State var model: SettingsViewModel
    @Bindable var account: AccountViewModel
    @Environment(\.colorScheme) private var scheme
    @State private var showingAccount = false
    @State private var showingTheme = false
    @State private var showingTime = false
    @State private var showingStatus = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MoopHeader(trailing: "your space")
                    .padding(.top, Space.cut)

                Text("Only yours.")
                    .font(MoopType.poster)
                    .foregroundStyle(Moop.ink)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.section)

                Text(account.tagline)
                    .font(MoopType.reading)
                    .foregroundStyle(Moop.ink.opacity(0.8))
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.cut)

                VStack(spacing: 0) {
                    MoopRow(label: "Name", value: model.name) { model.startEditingName() }
                    divider
                    MoopRow(label: "Evening reminder",
                            value: model.reminderOn ? "On · \(model.timeLabel)" : "Off") {
                        showingTime = true
                    }
                    divider
                    MoopRow(label: "Theme", value: model.themeLabel) { showingTheme = true }
                    divider
                    MoopRow(label: "Apple Intelligence", value: model.availability) { showingStatus = true }
                    divider
                    MoopRow(label: "Storage", value: account.mode.label) { showingAccount = true }
                    divider
                    MoopRow(label: "iCloud Sync", value: account.syncLabel) { showingAccount = true }
                    divider
                    MoopRow(label: account.busy ? "Working…" : "Save Backup to Files", chevron: true, action: account.askBackup)
                        .disabled(!model.canExport)
                    divider
                    MoopRow(label: account.busy ? "Checking backup…" : "Restore from Backup", chevron: true) {
                        account.showingImporter = true
                    }
                    .disabled(account.busy)
                    divider
                    ShareLink(items: model.fileURLs) {
                        MoopRow(label: "Export your moments", chevron: true)
                    }
                    .disabled(!model.canExport)
                    divider
                    MoopRow(label: "Delete everything", tint: Moop.alert, chevron: true,
                            action: account.requestWipe)
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

                Text("Privacy isn't a setting you need to turn on.")
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.ink.opacity(0.65))
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.section)
                    .padding(.bottom, Space.scene)
            }
        }
        .background(Moop.canvas)
        .task(id: "\(model.reminderOn)-\(model.reminderHour)-\(model.snapCount)") {
            await model.refreshSchedule()
        }
        .sheet(isPresented: $showingTheme) { themeSheet }
        .sheet(isPresented: $showingTime) { reminderSheet }
        .sheet(isPresented: $showingStatus) { statusSheet }
        .sheet(isPresented: $showingAccount) { accountSheet }
        .fileMover(isPresented: $account.showingExporter, file: account.exportFile) { account.exported($0) }
        .background(Color.clear.fileImporter(isPresented: $account.showingImporter,
                                              allowedContentTypes: [.zip]) { result in
            Task { await account.restore(from: result) }
        })
        .alert(item: $account.notice) { Alert(title: Text($0.title), message: Text($0.message)) }
        .alert("Save a backup?", isPresented: $account.confirmingBackup) {
            Button("Choose where to save") { Task { await account.makeBackup() } }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The backup is a plain file. Anyone with it may be able to view your moments, so keep it somewhere you trust.")
        }
        .alert(account.restoreTitle, isPresented: Binding(get: { account.restoreJob != nil },
                                                          set: { if !$0 { account.cancelRestore() } })) {
            Button("Merge", action: account.confirmRestore)
            Button("Cancel", role: .cancel, action: account.cancelRestore)
        } message: {
            Text(account.restoreMessage)
        }
        .alert(account.enableTitle, isPresented: $account.confirmingEnable) {
            Button("Merge moments", action: account.confirmEnable)
            Button("Keep on this iPhone for now", role: .cancel) {}
        } message: {
            Text("Your originals remain on this iPhone. Moments already in your iCloud are merged in, and nothing is overwritten.")
        }
        .alert("Stop syncing?", isPresented: $account.confirmingStop) {
            Button("Keep a local copy and stop syncing", action: account.stopSyncing)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("moop keeps every moment on this iPhone. Your moments stay in iCloud until you delete them there.")
        }
        .confirmationDialog("Delete everything?", isPresented: $account.confirmingWipeCloud, titleVisibility: .visible) {
            Button("Delete everywhere", role: .destructive, action: account.wipeEverywhere)
            Button("This iPhone only, and stop syncing", role: .destructive, action: account.wipeThisPhoneOnly)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Everywhere removes your moments from iCloud and from your other iPhones once they sync. A backup you saved to Files is not touched.")
        }
        .alert("Your name", isPresented: $model.editingName) {
            TextField("Optional", text: $model.draftName)
            Button("Cancel", role: .cancel) {}
            Button("Save", action: model.saveName)
        }
        .alert("Notifications are off", isPresented: $model.notificationsBlocked) {
            Button("Open Settings", action: openAppSettings)
            Button("Not now", role: .cancel) {}
        } message: {
            Text("moop can only remind you once iOS lets it send notifications.")
        }
        .alert("Delete everything?", isPresented: $account.confirmingWipe) {
            Button("Delete everything", role: .destructive, action: account.wipeLocal)
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Every photo and every word on this iPhone goes for good. A backup you saved to Files is not touched. This cannot be undone.")
        }
    }

    private var divider: some View {
        Rectangle().fill(Moop.veil).frame(height: 1)
    }

    private var themeSheet: some View {
        sheet("Light and night") {
            ForEach(Theme.allCases, id: \.rawValue) { option in
                MoopRow(label: model.label(for: option),
                        value: model.theme == option.rawValue ? "chosen" : nil) {
                    model.theme = option.rawValue
                    showingTheme = false
                }
                divider
            }
        }
    }

    private var reminderSheet: some View {
        sheet("Gentle evening") {
            Toggle("Evening reminder", isOn: Binding(
                get: { model.reminderOn },
                set: { wanted in Task { await model.setReminder(wanted) } }))
                .font(MoopType.reading)
                .tint(Moop.violet)
                .frame(height: 48)
            divider
            if model.reminderOn {
                DatePicker("Remind me at",
                           selection: Binding(get: { model.reminderTime },
                                              set: { model.setReminderTime($0) }),
                           displayedComponents: .hourAndMinute)
                    .font(MoopType.reading)
                    .frame(height: 48)
                divider
            }
            Text(model.scheduleLine)
                .font(MoopType.detail)
                .foregroundStyle(Moop.ink.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.cut)
        }
    }

    private var accountSheet: some View {
        sheet("Account & storage") {
            MoopRow(label: "Storage", value: account.mode.label)
            divider
            MoopRow(label: "iCloud Sync", value: account.syncLabel)
            if let last = account.lastSyncedLabel {
                divider
                MoopRow(label: "Last synced", value: last)
            }
            divider
            if let help = account.help {
                Text(help)
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.cut)
            }
            VStack(spacing: Space.cut) {
                if account.auth != .appleSignedIn {
                    SignInWithAppleButton(account.auth == .guest ? .continue : .signIn) { request in
                        request.requestedScopes = []
                    } onCompletion: { result in
                        showingAccount = false
                        Task { await account.handleApple(result) }
                    }
                    .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
                    .frame(height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
                } else if !account.syncEnabled {
                    MoopAction(title: "Enable iCloud Sync") {
                        showingAccount = false
                        Task { await account.requestEnable() }
                    }
                } else {
                    if account.canRetry { MoopAction(title: "Try Again", action: account.retry) }
                    MoopRow(label: "Stop iCloud Sync") {
                        showingAccount = false
                        account.confirmingStop = true
                    }
                }
                if account.auth != .guest {
                    MoopRow(label: "Use without Account", tint: Moop.alert) {
                        showingAccount = false
                        account.useWithoutAccount()
                    }
                }
            }
            .padding(.top, Space.beat)
        }
    }

    private var statusSheet: some View {
        sheet("On-device reader") {
            Text(model.availability)
                .font(MoopType.line)
                .foregroundStyle(Moop.ink)
            Text("moop reads your photo with Apple Intelligence on this iPhone. The picture is never uploaded, and no account is involved. If the reader is unavailable you can still keep photos without a word.")
                .font(MoopType.reading)
                .foregroundStyle(Moop.ink.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, Space.cut)
        }
    }

    private func sheet<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(MoopType.line)
                .foregroundStyle(Moop.ink)
                .padding(.bottom, Space.beat)
            content()
            Spacer()
        }
        .padding(Space.gutter)
        .padding(.top, Space.beat)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Moop.canvas)
        .presentationDetents([.height(420)])
        .presentationBackground(Moop.canvas)
        .presentationCornerRadius(Edge.block)
    }
}
