import SwiftUI

struct SettingsView: View {
    @State var model: SettingsViewModel

    var body: some View {
        List {
            Section("You") {
                Button(action: model.startEditingName) {
                    row("Name", value: model.name)
                }
            }

            Section {
                Toggle("Daily reminder", isOn: Binding(
                    get: { model.reminderOn },
                    set: { wanted in Task { await model.setReminder(wanted) } }))
                if model.reminderOn {
                    DatePicker("Remind me at",
                               selection: Binding(get: { model.reminderTime },
                                                  set: { model.setReminderTime($0) }),
                               displayedComponents: .hourAndMinute)
                }
            } header: {
                Text("Keeping it up")
            } footer: {
                if model.reminderOn { Text(model.scheduleLine) }
            }

            Section("Appearance") {
                Picker("Theme", selection: $model.theme) {
                    ForEach(Theme.allCases, id: \.rawValue) { Text($0.label).tag($0.rawValue) }
                }
            }

            Section("Apple Intelligence") {
                row("Status", value: model.availability)
            }

            Section {
                ShareLink(items: model.fileURLs) {
                    row("Export everything", value: "\(model.snapCount)")
                }
                .disabled(!model.canExport)
                Button(role: .destructive) { model.confirmingWipe = true } label: {
                    Text("Delete all snaps")
                }
            } header: {
                Text("Your snaps")
            } footer: {
                // the design has an icloud backup row that does not ship yet.
                // it needs the icloud capability and a move off local storage.
                // add the row and the second sentence together, never apart.
                Text("Your snaps stay on this iPhone.")
            }
        }
        .task(id: "\(model.reminderOn)-\(model.reminderHour)-\(model.snapCount)") {
            await model.refreshSchedule()
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Name", isPresented: $model.editingName) {
            TextField("Your name", text: $model.draftName)
            Button("Cancel", role: .cancel) {}
            Button("Save", action: model.saveName)
        }
        .alert("Notifications are off", isPresented: $model.notificationsBlocked) {
            Button("Open Settings", action: openAppSettings)
            Button("Not now", role: .cancel) {}
        } message: {
            Text("moop can only remind you once iOS lets it send notifications.")
        }
        .alert("Delete all snaps?", isPresented: $model.confirmingWipe) {
            Button("Delete everything", role: .destructive) { model.wipe() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every photo and every moop goes for good.")
        }
    }

    private func row(_ label: String, value: String) -> some View {
        HStack {
            Text(label).foregroundStyle(Color.inkPrimary)
            Spacer()
            Text(value).foregroundStyle(Color.inkSecondary)
        }
    }
}
