import SwiftUI

struct HistoryView: View {
    @State var model: HistoryViewModel

    @AppStorage(Prefs.name) private var name = "You"

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(name)
                    .font(.titleLarge)
                    .tracking(-0.4)
                    .foregroundStyle(Color.inkPrimary)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                ZStack {
                    if model.canPageBack { stackEdges(toward: -1) }
                    if model.canPageForward { stackEdges(toward: 1) }
                    monthCard
                        .offset(x: model.drag)
                        .rotationEffect(.degrees(model.tilt), anchor: .bottom)
                }
                .gesture(paging)
                .padding(.horizontal, 20)
                .padding(.top, 40)

                Group {
                    if model.isEmpty {
                        Text("Nothing here yet. Today is waiting.")
                            .font(.bodyDefault)
                            .foregroundStyle(Color.inkSecondary)
                    } else {
                        stats
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 30)
                .padding(.bottom, 40)
            }
        }
        .background(Color.canvas)
        .sheet(item: $model.openDay) { day in
            DayView(model: model.dayModel(for: day))
                .presentationDetents([.height(540), .large])
                .presentationDragIndicator(.visible)
                .presentationBackground(Color.canvas)
                .presentationCornerRadius(38)
        }
        .task { await model.hint() }
    }

    private var paging: some Gesture {
        DragGesture(minimumDistance: 20)
            .onChanged { model.dragChanged($0.translation) }
            .onEnded { model.dragEnded($0.translation) }
    }

    // the months before this one sit to the left, which is where a drag to the
    // right pulls them from
    private func stackEdges(toward side: CGFloat) -> some View {
        ForEach([2, 1], id: \.self) { depth in
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.surface)
                .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.hairline, lineWidth: 1))
                .padding(.vertical, CGFloat(depth) * 7)
                .offset(x: side * CGFloat(depth) * 11)
                .opacity(1 - Double(depth) * 0.28)
        }
    }

    private var monthCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text(model.title)
                    .font(.labelAction)
                    .tracking(-0.4)
                    .foregroundStyle(Color.inkPrimary)
                Spacer()
            }
            .padding(.horizontal, 16)
            .frame(height: 44)
            .background(Color.brandSoft)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 7),
                      spacing: 6) {
                ForEach(0..<42, id: \.self) { index in
                    dayCell(at: index)
                }
            }
            .padding(12)
        }
        .background(Color.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.hairline, lineWidth: 1))
    }

    @ViewBuilder
    private func dayCell(at index: Int) -> some View {
        let shape = RoundedRectangle(cornerRadius: 10, style: .continuous)
        if let cell = model.cell(at: index) {
            Group {
                if let image = cell.image {
                    Image(uiImage: image).resizable().scaledToFill()
                        .overlay(alignment: .topTrailing) {
                            if cell.count > 1 { countBadge(cell.count) }
                        }
                } else if cell.isToday {
                    Color.surface.overlay {
                        Image(systemName: "plus")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.brandFill)
                    }
                    .overlay(shape.stroke(Color.brandFill, lineWidth: 2))
                } else {
                    Color.hairline.opacity(0.55)
                }
            }
            .aspectRatio(1, contentMode: .fill)
            .clipShape(shape)
            .onTapGesture { model.open(cell) }
        } else {
            Color.clear.aspectRatio(1, contentMode: .fill)
        }
    }

    private func countBadge(_ count: Int) -> some View {
        Text("\(count)")
            .font(.system(size: 10, weight: .semibold))
            .foregroundStyle(Color.onDark)
            .frame(width: 18, height: 18)
            .background(Color.viewfinder.opacity(0.82), in: Circle())
            .padding(3)
    }

    private var stats: some View {
        HStack(spacing: 8) {
            Text("\(model.total) snaps")
                .font(.bodyDefault)
                .foregroundStyle(Color.inkSecondary)
            Text("·").font(.bodyDefault).foregroundStyle(Color.inkSecondary)
            HStack(spacing: 5) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 15))
                    .foregroundStyle(Color.streakFlame)
                Text("\(model.streak)-day streak")
                    .font(.bodyDefault)
                    .foregroundStyle(Color.streakFlame)
            }
        }
    }
}
