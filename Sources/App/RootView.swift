import SwiftUI

struct RootView: View {
    @State private var app = AppViewModel()
    @Environment(\.scenePhase) private var phase

    @AppStorage(Prefs.onboarded) private var onboarded = false
    @AppStorage(Prefs.theme) private var theme = Theme.system.rawValue
    @AppStorage(Prefs.reminderOn) private var reminderOn = false
    @AppStorage(Prefs.reminderHour) private var reminderHour = 20

    var body: some View {
        Group {
            if app.showingSplash {
                SplashView { withAnimation(.easeOut(duration: 0.25)) { app.splashFinished() } }
            } else if !onboarded {
                FirstRunView { onboarded = true }
            } else {
                tabs
            }
        }
        .preferredColorScheme(Theme(rawValue: theme)?.scheme)
        .onChange(of: app.snaps.snaps.count) { _, _ in arm() }
        .onChange(of: phase) { _, new in if new == .active { arm() } }
        .task { arm() }
    }

    // the tab bar sits under every screen, pushes included, which is how the
    // design draws the day detail and the streak
    private var tabs: some View {
        @Bindable var app = app
        return VStack(spacing: 0) {
            Group {
                switch app.tab {
                case .today:    todayTab
                case .history:  historyTab
                case .settings: SettingsView(model: SettingsViewModel(snaps: app.snaps))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            MoopTabBar(selection: $app.tab) { tab in
                switch tab {
                case .today: app.todayPath.removeAll()
                case .history: app.historyPath.removeAll()
                case .settings: break
                }
            }
        }
        .background(Moop.canvas)
        .fullScreenCover(isPresented: $app.showingCamera) {
            CameraFlow(model: CameraViewModel(reader: app.reader, snaps: app.snaps),
                       reader: app.reader, snaps: app.snaps,
                       close: app.cameraFinished)
        }
    }

    private var todayTab: some View {
        @Bindable var app = app
        return NavigationStack(path: $app.todayPath) {
            TodayView(model: TodayViewModel(snaps: app.snaps),
                      open: app.openCamera,
                      openStreak: { app.todayPath.append(.streak) })
                .navigationBarHidden(true)
                .navigationDestination(for: TodayRoute.self) { route in
                    switch route {
                    case .streak:
                        StreakView(model: StreakViewModel(snaps: app.snaps),
                                   back: app.popToday)
                            .navigationBarHidden(true)
                    case .result:
                        ResultView(model: ResultViewModel(reader: app.reader, snaps: app.snaps),
                                   keepWithout: {},
                                   done: { app.reader.reset(); app.backToToday() })
                            .navigationBarHidden(true)
                    case .explanation:
                        WhySheet(mood: app.reader.result?.mood, because: app.reader.result?.because)
                    }
                }
        }
    }

    private var historyTab: some View {
        @Bindable var app = app
        return NavigationStack(path: $app.historyPath) {
            HistoryView(model: HistoryViewModel(snaps: app.snaps),
                        open: { app.historyPath.append($0) })
                .navigationBarHidden(true)
                .navigationDestination(for: HistoryRoute.self) { route in
                    switch route {
                    case .day(let date):
                        DayView(model: DayViewModel(day: date, snaps: app.snaps),
                                back: app.popHistory)
                            .navigationBarHidden(true)
                    case .compare(let month):
                        CompareView(model: HistoryViewModel(snaps: app.snaps, anchor: month),
                                    back: app.popHistory)
                            .navigationBarHidden(true)
                    }
                }
        }
    }

    private func arm() { app.armReminder(hour: reminderHour, enabled: reminderOn) }
}
