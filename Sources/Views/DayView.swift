import SwiftUI

struct DayView: View {
    @State var model: DayViewModel
    var back: () -> Void

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                MoopHeader(trailing: model.countLabel)
                    .padding(.top, Space.cut)

                MoopBack(label: "your story", action: back)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.tick)

                Text(model.title)
                    .font(MoopType.poster)
                    .foregroundStyle(Moop.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.beat)

                if model.isEmpty {
                    empty
                } else {
                    ForEach(model.shots) { snap in
                        moment(snap)
                            .padding(.horizontal, Space.gutter)
                            .padding(.top, Space.section)
                    }
                }
            }
            // a whole day can be ten photos. the last one gets room to breathe
            // above the tab bar rather than sitting on it.
            .padding(.bottom, Space.scene)
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

    private func moment(_ snap: Snap) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            PhotoCard(image: model.image(for: snap))

            HStack(alignment: .firstTextBaseline) {
                Text(model.mood(of: snap))
                    .font(MoopType.title)
                    .foregroundStyle(snap.isLabelled ? Moop.ink : Moop.ink.opacity(0.55))
                Spacer()
                Text(model.time(of: snap))
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.ink.opacity(0.7))
                MoopTrash(what: "the \(model.time(of: snap)) moment") { model.ask(snap) }
            }
            .padding(.top, Space.cut)

            if let sentence = snap.sentence {
                Text(sentence)
                    .font(MoopType.reading)
                    .foregroundStyle(Moop.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, Space.tick)
            }
        }
    }

    private var empty: some View {
        VStack(alignment: .leading, spacing: Space.cut) {
            Text("Nothing was saved on this day.")
                .font(MoopType.statement)
                .foregroundStyle(Moop.ink)
            Text("A gap is part of the story, too.")
                .font(MoopType.reading)
                .foregroundStyle(Moop.ink.opacity(0.7))
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.section)
    }
}
