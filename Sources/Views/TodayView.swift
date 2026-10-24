import SwiftUI

struct TodayView: View {
    @State var model: TodayViewModel
    var open: () -> Void
    var openStreak: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MoopHeader(trailing: model.dateLine)
                    .padding(.top, Space.cut)

                Text(model.headline)
                    .font(MoopType.poster)
                    .foregroundStyle(Moop.ink)
                    .lineSpacing(-6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.section)

                if model.saved { savedStrip } else { openStrip }

                if let latest = model.latest {
                    PhotoCard(image: model.image(for: latest))
                        .padding(.horizontal, Space.gutter)
                        .padding(.top, Space.beat)
                }

                if let latest = model.latest, let mood = latest.moodCase {
                    Text(mood.rawValue)
                        .font(MoopType.line)
                        .foregroundStyle(Moop.ink)
                        .padding(.horizontal, Space.gutter)
                        .padding(.top, Space.cut)
                    if let sentence = latest.sentence {
                        Text(sentence)
                            .font(MoopType.reading)
                            .foregroundStyle(Moop.ink.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.horizontal, Space.gutter)
                            .padding(.top, Space.dot)
                    }
                } else if model.saved {
                    Text("kept without a word")
                        .font(MoopType.line)
                        .foregroundStyle(Moop.ink.opacity(0.55))
                        .padding(.horizontal, Space.gutter)
                        .padding(.top, Space.cut)
                }

                Text(model.note)
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.ink.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.beat)

                MoopAction(title: model.actionTitle, action: open)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.cut)
                    .padding(.bottom, Space.scene)
            }
        }
        .background(Moop.canvas)
    }

    private var savedStrip: some View {
        HStack {
            MoopBadge(text: "today is saved")
            Spacer()
            Button(action: openStreak) {
                Text("\(model.streak)-day rhythm ↗")
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.violet)
            }
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.beat)
    }

    private var openStrip: some View {
        HStack(spacing: Space.cut) {
            Circle().fill(Moop.violet).frame(width: 10, height: 10)
            VStack(alignment: .leading, spacing: 2) {
                Text("Not snapped today")
                    .font(MoopType.statement)
                    .foregroundStyle(Moop.ink)
                Text("Your place is still open.")
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.ink.opacity(0.7))
            }
            Spacer()
        }
        .padding(Space.beat)
        .background(Moop.veil, in: RoundedRectangle(cornerRadius: Edge.soft, style: .continuous))
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.beat)
    }
}
