import AuthenticationServices
import SwiftUI

// the first thing a new person decides, and neither answer is the small print.
struct StorageChoiceView: View {
    @Bindable var model: AccountViewModel
    @Environment(\.colorScheme) private var scheme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MoopHeader(trailing: "private")
                .padding(.top, Space.scene)

            switch model.step {
            case .choice: choice
            case .checking: checking
            case .ready: ready
            case .unavailable: unavailable
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Moop.canvas)
        .alert(item: $model.notice) { Alert(title: Text($0.title), message: Text($0.message)) }
    }

    private var choice: some View {
        Group {
            Text("Keep your moments your way.")
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

            // the real button, as Apple asks. no email or name is requested.
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = []
            } onCompletion: { result in
                Task { await model.handleApple(result) }
            }
            .signInWithAppleButtonStyle(scheme == .dark ? .white : .black)
            .frame(height: 54)
            .clipShape(RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.section)

            caption("Sync your moments privately through iCloud.")

            Button(action: model.chooseLocal) {
                Text("Continue without Account")
                    .font(MoopType.statement)
                    .foregroundStyle(Moop.ink)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(Moop.veil, in: RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.beat)

            caption("Stay on this iPhone. Back up to Files whenever you like.")

            Spacer()

            Text("No feed. No posting. Your moments stay private.")
                .font(MoopType.detail)
                .foregroundStyle(Moop.ink.opacity(0.7))
                .padding(.horizontal, Space.gutter)
                .padding(.bottom, Space.scene)
        }
    }

    private var checking: some View {
        Group {
            Text("One moment.")
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)
            ProgressView("Checking iCloud")
                .tint(Moop.violet)
                .foregroundStyle(Moop.ink.opacity(0.7))
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)
            Spacer()
        }
    }

    private var ready: some View {
        Group {
            Text("Turn on iCloud Sync?")
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)
            caption("Your moments are stored privately in your own iCloud account and show up on your other iPhones. Everything is saved on this iPhone first, so moop works offline.")
            Spacer()
            MoopAction(title: "Turn on iCloud Sync", action: model.enableFromOnboarding)
                .padding(.horizontal, Space.gutter)
            Button("Not now", action: model.finishOnboarding)
                .font(MoopType.reading)
                .foregroundStyle(Moop.violet)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)
                .padding(.bottom, Space.scene)
        }
    }

    private var unavailable: some View {
        Group {
            Text("Signed in. iCloud is off.")
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)
            caption("You're signed in, but iCloud isn't available on this iPhone. Your moments will stay here until sync is enabled.")
            caption(model.availability.explanation)
            Spacer()
            MoopAction(title: "continue", action: model.finishOnboarding)
                .padding(.horizontal, Space.gutter)
                .padding(.bottom, Space.scene)
        }
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(MoopType.detail)
            .foregroundStyle(Moop.ink.opacity(0.75))
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.tick)
    }
}
