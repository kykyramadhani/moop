import SwiftUI

struct ResultView: View {
    @State var model: ResultViewModel

    var body: some View {
        if let mood = model.mood, let photo = model.photo, let sentence = model.sentence {
            content(mood: mood, photo: photo, sentence: sentence)
        }
    }

    private func content(mood: Mood, photo: UIImage, sentence: String) -> some View {
        VStack(spacing: 28) {
            Spacer()
            Image(uiImage: photo)
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                .shadow(color: .black.opacity(0.14), radius: 10, y: 8)

            VStack(spacing: 8) {
                Text("YOUR MOOP")
                    .font(.overline)
                    .tracking(0.6)
                    .foregroundStyle(Color.inkSecondary)
                Text(mood.display)
                    .font(.displayMood)
                    .tracking(-0.4)
                    .foregroundStyle(mood.ink)
                Text(sentence)
                    .font(.bodyLarge)
                    .tracking(-0.4)
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 300)

                Button { Task { await model.reword() } } label: {
                    Label("Reword", systemImage: "sparkles")
                        .font(.labelAction)
                        .foregroundStyle(Color.brandText)
                        .frame(height: 44)
                }
                .disabled(model.rewording)
                .opacity(model.rewording ? 0.4 : 1)
            }
            Spacer()
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: [mood.field.top, mood.field.bottom],
                           startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .safeAreaInset(edge: .bottom) {
            Button("Snap again", action: model.again)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
        }
    }
}
