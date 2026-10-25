import SwiftUI

struct CompareView: View {
    @State var model: HistoryViewModel
    var back: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MoopHeader(trailing: "your year")
                    .padding(.top, Space.cut)

                MoopBack(label: "your story", action: back)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.tick)

                Text("Not the same\nkind of month.")
                    .font(MoopType.poster)
                    .foregroundStyle(Moop.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.section)

                HStack(spacing: Space.section) {
                    tag(model.monthName(model.previousMonth), tint: Moop.veil, on: Moop.ink)
                    tag(model.monthName(model.anchor), tint: Moop.citrus, on: Moop.onAccent)
                }
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

                ForEach(Mood.allCases.filter { $0 != .mystery }, id: \.self) { mood in
                    row(mood)
                        .padding(.horizontal, Space.gutter)
                        .padding(.top, Space.beat)
                }

                Text(verdict)
                    .font(MoopType.statement)
                    .foregroundStyle(Moop.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.section)

                Text("Only the moments you saved are counted. Missing days aren't guesses.")
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.ink.opacity(0.75))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.beat)
                    .padding(.bottom, Space.scene)
            }
        }
        .background(Moop.canvas)
    }

    private func tag(_ text: String, tint: Color, on ink: Color) -> some View {
        Text(text.uppercased())
            .font(MoopType.detail)
            .foregroundStyle(ink)
            .frame(width: 140, height: 31)
            .background(tint, in: RoundedRectangle(cornerRadius: Edge.slight, style: .continuous))
    }

    private func row(_ mood: Mood) -> some View {
        let before = share(mood, in: model.previousMonth)
        let now = share(mood, in: model.anchor)
        return VStack(alignment: .leading, spacing: Space.tick) {
            Text(mood.rawValue.uppercased())
                .font(MoopType.micro)
                .foregroundStyle(Moop.ink)
            HStack(spacing: Space.section) {
                bar(before, mood: mood)
                bar(now, mood: mood)
            }
        }
    }

    private func bar(_ fraction: Double, mood: Mood) -> some View {
        GeometryReader { geo in
            RoundedRectangle(cornerRadius: Edge.slight, style: .continuous)
                .fill(Moop.emotion(mood))
                .frame(width: max(geo.size.width * fraction, fraction > 0 ? 10 : 0))
        }
        .frame(height: 24)
    }

    private func share(_ mood: Mood, in month: Date) -> Double {
        model.shares(for: month).first { $0.mood == mood }?.fraction ?? 0
    }

    // said plainly, from the counts, rather than invented
    private var verdict: String {
        let now = model.shares(for: model.anchor).max { $0.fraction < $1.fraction }
        let before = model.shares(for: model.previousMonth).max { $0.fraction < $1.fraction }
        guard let now else { return "Not enough saved yet to tell these months apart." }
        if let before, before.mood == now.mood {
            return "Both months leaned \(now.mood.rawValue)."
        }
        return "\(model.monthName(model.anchor)) felt more \(now.mood.rawValue) than the month before it."
    }
}
