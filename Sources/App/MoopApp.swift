import SwiftUI

@main
struct MoopApp: App {
    init() {
        #if DEBUG
        StreakReminder.check()
        Task { await MoodEngine.probe() }
        #endif
    }

    var body: some Scene {
        WindowGroup { RootView() }
    }
}
