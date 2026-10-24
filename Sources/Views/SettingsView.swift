import SwiftUI

struct SettingsView: View {
    @State var model: SettingsViewModel
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

                Text("No account. No feed. Stored on this iPhone.")
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
                    ShareLink(items: model.fileURLs) {
                        MoopRow(label: "Export your moments", chevron: true)
                    }
                    .disabled(!model.canExport)
                    divider
                    MoopRow(label: "Delete everything", tint: Moop.alert, chevron: true) {
                        model.confirmingWipe = true
                    }
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
        .alert("Delete everything?", isPresented: $model.confirmingWipe) {
            Button("Delete everything", role: .destructive) { model.wipe() }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("Every photo and every word goes for good. This cannot be undone.")
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
