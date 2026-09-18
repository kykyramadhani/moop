import SwiftUI

struct OnboardingView: View {
    @State private var model = OnboardingViewModel()
    @FocusState private var typing: Bool
    var onDone: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Color.clear.frame(height: 54)

            Text("First, what should we call you?")
                .font(.titleQuestion)
                .tracking(-0.3)
                .foregroundStyle(Color.inkPrimary)
                .frame(width: 342, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 12)

            // the only thing asked of her, so it is also where the privacy
            // question gets answered
            Text("It goes on your own history and nowhere else. Your snaps never leave this iPhone.")
                .font(.bodyDefault)
                .foregroundStyle(Color.inkSecondary)
                .frame(width: 342, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)

            nameField

            Spacer()

            Button("Continue") {
                typing = false
                model.finish()
                onDone()
            }
            .buttonStyle(PrimaryButtonStyle())
            .opacity(model.canContinue ? 1 : 0.45)
            .disabled(!model.canContinue)
            .padding(.horizontal, 20)
            .padding(.bottom, 34)
        }
        .background(Color.canvas)
    }

    private var nameField: some View {
        let active = typing || model.canContinue
        return TextField("", text: $model.name,
                         prompt: Text("Your name").foregroundStyle(Color.inkSecondary))
            .font(.labelOption)
            .foregroundStyle(Color.inkPrimary)
            .tint(Color.brandFill)
            .focused($typing)
            .submitLabel(.done)
            .padding(.horizontal, 16)
            .frame(height: 54)
            .background(Color.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(active ? Color.brandFill : Color.hairline, lineWidth: active ? 1.5 : 1)
            )
            .padding(.horizontal, 20)
            .padding(.top, 28)
    }
}
