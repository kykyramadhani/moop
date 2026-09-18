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
                OnboardingView { onboarded = true }
            } else {
                stack
            }
        }
        .preferredColorScheme(Theme(rawValue: theme)?.scheme)
        .onChange(of: app.snaps.snaps.count) { _, _ in arm() }
        .onChange(of: phase) { _, new in if new == .active { arm() } }
        .task { arm() }
    }

    private var stack: some View {
        @Bindable var navigator = app.navigator
        return NavigationStack(path: $navigator.path) {
            HomeView(model: HomeViewModel(reader: app.reader,
                                          snaps: app.snaps,
                                          navigator: app.navigator))
                .navigationDestination(for: Route.self, destination: screen)
        }
    }

    @ViewBuilder
    private func screen(for route: Route) -> some View {
        switch route {
        case .result:
            ResultView(model: ResultViewModel(reader: app.reader,
                                              snaps: app.snaps,
                                              navigator: app.navigator))
        case .history:
            HistoryView(model: HistoryViewModel(snaps: app.snaps))
        case .settings:
            SettingsView(model: SettingsViewModel(snaps: app.snaps))
        }
    }

    private func arm() {
        app.armReminder(hour: reminderHour, enabled: reminderOn)
    }
}
