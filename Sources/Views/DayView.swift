import SwiftUI

struct DayView: View {
    @State var model: DayViewModel
    var back: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Button(action: back) {
                    Text("‹  your story")
                        .font(MoopType.detail)
                        .foregroundStyle(Moop.violet)
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.cut)

                Text(model.title)
                    .font(MoopType.poster)
                    .foregroundStyle(Moop.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.section)

                Text(model.countLabel)
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.ink)
                    .padding(.horizontal, Space.cut)
                    .frame(height: 30)
                    .background(Moop.citrus, in: RoundedRectangle(cornerRadius: Edge.slight, style: .continuous))
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.beat)

                if let hero = model.hero { heroBlock(hero) }
                if !model.rest.isEmpty { restRow }

                Spacer(minLength: Space.scene)
            }
        }
        .background(Moop.canvas)
        .alert("Delete this moment?", isPresented: $model.confirmingDelete) {
            Button("Delete", role: .destructive) { model.delete() }
            Button("Keep it", role: .cancel) {}
        } message: {
            Text("The photo and its word go for good. Everything else from that day stays.")
        }
        .onChange(of: model.dismissed) { _, gone in if gone { back() } }
    }

    private func heroBlock(_ snap: Snap) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(uiImage: model.image(for: snap) ?? UIImage())
                .resizable().scaledToFill()
                .frame(height: 208)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
                .padding(.top, Space.beat)

            HStack(alignment: .firstTextBaseline) {
                Text(snap.moodCase?.rawValue ?? "kept without a word")
                    .font(MoopType.title)
                    .foregroundStyle(snap.moodCase == nil ? Moop.ink.opacity(0.55) : Moop.ink)
                Spacer()
                HStack(spacing: Space.dot) {
                    Text(model.time(of: snap))
                    Text("·")
                    Button("delete") { model.confirmingDelete = true }
                }
                .font(MoopType.detail)
                .foregroundStyle(Moop.violet)
            }
            .padding(.top, Space.beat)

            if let sentence = snap.sentence {
                Text(sentence)
                    .font(MoopType.reading)
                    .foregroundStyle(Moop.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.tick)
            }
        }
        .padding(.horizontal, Space.gutter)
    }

    // the rest of the day sits underneath as a row, smaller, with its own times
    private var restRow: some View {
        HStack(alignment: .top, spacing: Space.cut) {
            ForEach(model.rest) { snap in
                Button { model.focus(snap) } label: {
                    VStack(alignment: .leading, spacing: Space.tick) {
                        Image(uiImage: model.image(for: snap) ?? UIImage())
                            .resizable().scaledToFill()
                            .frame(height: 91)
                            .frame(maxWidth: .infinity)
                            .clipShape(RoundedRectangle(cornerRadius: Edge.slight, style: .continuous))
                        Text("\(model.time(of: snap)) · \(snap.moodCase?.rawValue ?? "no word")")
                            .font(MoopType.micro)
                            .foregroundStyle(Moop.ink)
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.section)
    }
}
