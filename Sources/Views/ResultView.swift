import SwiftUI

struct ResultView: View {
    @State var model: ResultViewModel
    var keepWithout: () -> Void
    var done: () -> Void

    var body: some View {
        Group {
            if model.failed { unsure } else { read }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .sheet(isPresented: $model.showingWhy) {
            WhySheet(mood: model.mood, because: model.because)
                .presentationDetents([.height(330)])
                .presentationBackground(Moop.canvas)
                .presentationCornerRadius(Edge.block)
        }
    }

    private var read: some View {
        // a square photo needs its width to decide its height. a spacer-driven
        // column hands it the leftover height instead and shrinks it.
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
            MoopHeader(trailing: "saved · " + Date.now.formatted(.dateTime.day().month(.abbreviated)))
                .padding(.top, Space.cut)

            Text("This one felt…")
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            // the photo takes the full width as a square and the word sits
            // under it, so nothing is left standing in an empty column
            PhotoCard(image: model.photo)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            moodCard
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.cut)

            if let sentence = model.sentence {
                Text("“\(sentence)”")
                    .font(MoopType.statement)
                    .foregroundStyle(Moop.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.beat)
            }

            Rectangle().fill(Moop.veil).frame(height: 1)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            HStack {
                Button("Why this word?") { model.showingWhy = true }
                    .font(MoopType.reading)
                    .foregroundStyle(Moop.ink)
                Spacer()
                Button(model.rewording ? "…" : "Try another line") {
                    Task { await model.anotherLine() }
                }
                .font(MoopType.detail)
                .foregroundStyle(Moop.violet)
                .disabled(model.rewording)
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.beat)

            MoopAction(title: "keep this snap", action: done)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)
                .padding(.bottom, Space.scene)
            }
        }
        .background(Moop.canvas)
    }

    private var moodCard: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: Space.dot) {
                Text(model.position.uppercased())
                    .font(MoopType.micro)
                    .foregroundStyle(Moop.onAccent.opacity(0.7))
                Text(model.mood?.rawValue ?? "")
                    .font(MoopType.moodWord)
                    .foregroundStyle(Moop.onAccent)
            }
            Spacer()
            // the reader is a suggestion and the screen says so, every time
            Text("a guess,\nnot a verdict")
                .font(MoopType.detail)
                .foregroundStyle(Moop.onAccent.opacity(0.8))
                .multilineTextAlignment(.trailing)
        }
        .padding(Space.beat)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(model.mood.map(Moop.emotion) ?? Moop.citrus,
                    in: RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
    }

    private var unsure: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("moop.").font(MoopType.title).foregroundStyle(Moop.onDark)
                Spacer()
                Text("READ UNSURE")
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.onDark.opacity(0.8))
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.scene)

            Text("Some moments\nwon't fit a word.")
                .font(MoopType.poster)
                .foregroundStyle(Moop.onDark)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

            if let photo = model.photo {
                PhotoCard(image: photo)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.beat)
            }

            Text("READ FAILED · MYSTERY")
                .font(MoopType.detail)
                .foregroundStyle(Moop.onDark)
                .padding(.horizontal, Space.cut)
                .frame(height: 30)
                .background(Moop.onDark.opacity(0.14),
                            in: RoundedRectangle(cornerRadius: Edge.slight, style: .continuous))
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            Text("We couldn't read this photo reliably. That doesn't make your day mysterious.")
                .font(MoopType.reading)
                .foregroundStyle(Moop.onDark.opacity(0.9))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            MoopAction(title: "try reading again") { Task { await model.retry() } }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

            Button("Keep the photo without a mood") {
                keepWithout()
                done()
            }
            .font(MoopType.reading)
            .foregroundStyle(Moop.onDark.opacity(0.85))
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.beat)
            .padding(.bottom, Space.scene)
            }
        }
        .background(Moop.scene.ignoresSafeArea())
        .preferredColorScheme(.dark)
    }
}

struct WhySheet: View {
    let mood: Mood?
    let because: String?

    var body: some View {
        VStack(alignment: .leading, spacing: Space.beat) {
            Text("Why \(mood?.rawValue ?? "that")?")
                .font(MoopType.line)
                .foregroundStyle(Moop.ink)
            Text(because ?? "The reader did not give a reason for this one.")
                .font(MoopType.reading)
                .foregroundStyle(Moop.ink.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Rectangle().fill(Moop.veil).frame(height: 1)
            Text("moop reads light, colour and what is in the frame. It cannot know your day, only the picture of it.")
                .font(MoopType.detail)
                .foregroundStyle(Moop.ink.opacity(0.7))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
        }
        .padding(Space.gutter)
        .padding(.top, Space.beat)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Moop.canvas)
    }
}
