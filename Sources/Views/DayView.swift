import SwiftUI

struct DayView: View {
    @State var model: DayViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // the day is a deck: swipe it. the dots say how deep it goes.
                TabView(selection: $model.index) {
                    ForEach(Array(model.shots.enumerated()), id: \.element.id) { position, snap in
                        photo(snap).tag(position)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: 280)

                if model.showsDots { dots }
                if let current = model.current { caption(current) }
            }
            .padding(.top, 28)
            .padding(.bottom, 40)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .animation(.easeOut(duration: 0.2), value: model.index)
        .overlay(alignment: .topTrailing) { trashButton }
        .onChange(of: model.dismissed) { _, gone in if gone { dismiss() } }
        .alert("Delete this snap?", isPresented: $model.confirmingDelete) {
            Button("Delete", role: .destructive) { model.delete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("The photo and its moop go for good.")
        }
    }

    private func photo(_ snap: Snap) -> some View {
        Group {
            if let image = model.image(for: snap) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                Color.hairline
            }
        }
        .frame(width: 280, height: 280)
        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .frame(maxWidth: .infinity)
    }

    private var dots: some View {
        HStack(spacing: 6) {
            ForEach(model.shots.indices, id: \.self) { i in
                Circle()
                    .fill(Color.inkSecondary)
                    .opacity(i == model.index ? 1 : 0.3)
                    .frame(width: 6, height: 6)
            }
        }
        .animation(.easeOut(duration: 0.2), value: model.index)
    }

    private func caption(_ snap: Snap) -> some View {
        VStack(spacing: 8) {
            Text(model.dateLine)
                .font(.overline)
                .tracking(0.6)
                .foregroundStyle(Color.inkSecondary)
            Text(snap.moodCase.display)
                .font(.displayMood)
                .tracking(-0.4)
                .foregroundStyle(snap.moodCase.ink)
            if let sentence = snap.sentence {
                Text(sentence)
                    .font(.bodyLarge)
                    .tracking(-0.4)
                    .foregroundStyle(Color.inkSecondary)
                    .multilineTextAlignment(.center)
                    // however long it runs, show all of it
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(width: 300)
            }
        }
        .id(snap.id)
        .transition(.opacity)
    }

    private var trashButton: some View {
        Button { model.confirmingDelete = true } label: {
            Image(systemName: "trash")
                .font(.system(size: 17))
                .foregroundStyle(Color.danger)
                .frame(width: 44, height: 44)
        }
        .padding(.trailing, 12)
        .padding(.top, 8)
    }
}
