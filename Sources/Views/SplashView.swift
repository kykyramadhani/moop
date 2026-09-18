import Lottie
import SwiftUI

// the lottie file is the whole screen. retiming it is a re-export, not a code
// change.
struct SplashView: View {
    var onFinish: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Color.canvas
            // one fitting system, not two: the view takes the whole screen and
            // lottie centres the composition inside it
            LottieView(animation: .named(scheme == .dark ? "splash-dark" : "splash-light"))
                .playing(loopMode: .playOnce)
                .animationDidFinish { _ in onFinish() }
                .configure { $0.contentMode = .scaleAspectFill }
                .resizable()
        }
        .ignoresSafeArea()
        .task {
            // a missing file never calls back and would hold the app here
            // forever. onFinish only flips a flag, so twice is once.
            try? await Task.sleep(for: .milliseconds(2200))
            onFinish()
        }
    }
}
