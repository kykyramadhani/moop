import SwiftUI

struct StreakView: View {
    @State var model: StreakViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline) {
                Text("moop.").font(MoopType.title).foregroundStyle(Moop.ink)
                Spacer()
                Text("YOUR RHYTHM")
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.ink.opacity(0.75))
            }
            .padding(.horizontal, Space.gutter)
            .padding(.top, Space.cut)

            Text(model.headline)
                .font(MoopType.poster)
                .foregroundStyle(Moop.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

            card
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.scene)

            dots
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

            Text("Miss one day? Your streak holds. Miss two in a row? The count starts again.")
                .font(MoopType.statement)
                .foregroundStyle(Moop.ink)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.section)

            Text("All past snaps stay, no matter what.")
                .font(MoopType.reading)
                .foregroundStyle(Moop.ink.opacity(0.8))
                .padding(.horizontal, Space.gutter)
                .padding(.top, Space.beat)

            }
            .padding(.bottom, Space.scene)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Moop.canvas)
    }

    private var card: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: Space.beat) {
                Text("\(model.count)")
                    .font(MoopType.poster)
                    .foregroundStyle(Moop.ink)
                Text("day streak")
                    .font(MoopType.title)
                    .foregroundStyle(Moop.ink)
            }
            Spacer()
            Text(model.reassurance)
                .font(MoopType.statement)
                .foregroundStyle(Moop.ink)
        }
        .padding(Space.beat)
        .frame(maxWidth: .infinity, minHeight: 188, alignment: .leading)
        .background(Moop.citrus, in: RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
    }

    private var dots: some View {
        HStack(spacing: Space.cut) {
            ForEach(model.week) { day in
                Text(day.letter)
                    .font(MoopType.detail)
                    .foregroundStyle(day.saved || day.isToday ? Moop.onDark : Moop.ink)
                    .frame(width: 38, height: 38)
                    .background(fill(day), in: Circle())
                    .accessibilityLabel("\(day.letter), \(day.saved ? "saved" : "nothing saved")")
            }
        }
    }

    private func fill(_ day: StreakViewModel.Day) -> Color {
        if day.isToday { return Moop.citrus }
        return day.saved ? Moop.violet : Moop.veil
    }
}
