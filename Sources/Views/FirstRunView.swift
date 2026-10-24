import SwiftUI

struct FirstRunView: View {
    @State private var model = OnboardingViewModel()
    @FocusState private var typing: Bool
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            MoopHeader(trailing: "private")
                .padding(.top, Space.scene)

            Text("Nobody else\nis reading this.")
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

            Text("One photo a day. moop gives it a word. No account, no feed, and it never leaves this iPhone.")
                .font(MoopType.reading)
                .foregroundStyle(Moop.ink.opacity(0.8))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            TextField("", text: $model.name,
                      prompt: Text("What should we call you?").foregroundStyle(Moop.ink.opacity(0.45)))
                .font(MoopType.reading)
                .foregroundStyle(Moop.ink)
                .tint(Moop.violet)
                .focused($typing)
                .submitLabel(.done)
                .padding(.horizontal, Space.beat)
                .frame(height: 54)
                .background(Moop.highlight, in: RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

            Text("Optional. It only ever shows up here.")
                .font(MoopType.detail)
                .foregroundStyle(Moop.ink.opacity(0.6))
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.tick)

            Spacer()

            MoopAction(title: "start") {
                typing = false
                model.finish()
                onDone()
            }
            .padding(.horizontal, Space.gutter)
            .padding(.bottom, Space.scene)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Moop.canvas)
    }
}
