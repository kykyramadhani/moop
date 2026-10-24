import Lottie
import SwiftUI

// the lottie file is the whole screen. retiming it is a re-export, not a code
// change.
struct SplashView: View {
    var onFinish: () -> Void

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        ZStack {
            Moop.canvas
            // one fitting system, not two: the view takes the whole screen and
            // lottie centres the composition inside it
            LottieView(animation: .named(scheme == .dark ? "splash-dark" : "splash-light"))
                .playing(loopMode: .playOnce)
                .animationDidFinish { _ in onFinish() }
                .configure {
                    $0.contentMode = .scaleAspectFill
                    $0.fontProvider = MoopFontProvider()
                }
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

// the json names the face the way figma does, "DM Sans-Bold", which is not the
// postscript name the bundle registers. map it rather than renaming the files.
struct MoopFontProvider: AnimationFontProvider {
    func fontFor(family: String, size: CGFloat) -> CTFont? {
        let name = family.replacingOccurrences(of: "DM Sans", with: "DMSans")
        return CTFontCreateWithName(name as CFString, size, nil)
    }
}
