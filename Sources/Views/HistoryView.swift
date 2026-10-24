import SwiftUI

struct HistoryView: View {
    @State var model: HistoryViewModel
    var open: (HistoryRoute) -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                MoopHeader(trailing: model.rangeLabel)
                    .padding(.top, Space.cut)

                Text(model.lens == .month ? model.monthHeadline : model.headline)
                    .font(MoopType.poster)
                    .foregroundStyle(Moop.ink)
                    .lineSpacing(-6)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.section)

                lensPicker
                    .padding(.horizontal, Space.gutter)
                    .padding(.top, Space.beat)

                switch model.lens {
                case .week: weekList
                case .calendar: calendar
                case .month: comparison
                }
            }
            .padding(.bottom, Space.scene)
        }
        .background(Moop.canvas)
        .onChange(of: model.openDay) { _, day in
            guard let day else { return }
            model.openDay = nil
            open(.day(day))
        }
    }

    private var lensPicker: some View {
        HStack(spacing: Space.beat) {
            ForEach(HistoryViewModel.Lens.allCases, id: \.self) { lens in
                Button { model.lens = lens } label: {
                    if model.lens == lens {
                        MoopBadge(text: lens.rawValue)
                    } else {
                        Text(lens.rawValue.capitalized)
                            .font(MoopType.detail)
                            .foregroundStyle(Moop.violet)
                    }
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }

    // MARK: week

    private var weekList: some View {
        VStack(spacing: Space.tick) {
            ForEach(model.week) { row in
                Button { model.open(row) } label: {
                    HStack(spacing: Space.beat) {
                        Text(row.stamp)
                            .font(MoopType.detail)
                            .foregroundStyle(Moop.onAccent)
                            .frame(width: 54, alignment: .leading)
                        Text(row.line)
                            .font(MoopType.reading)
                            .foregroundStyle(Moop.onAccent)
                            .lineLimit(1)
                        Spacer()
                    }
                    .padding(.horizontal, Space.beat)
                    .frame(height: 50)
                    .background(row.mood.map(Moop.emotion) ?? Moop.veil,
                                in: RoundedRectangle(cornerRadius: Edge.slight, style: .continuous))
                }
                .buttonStyle(.plain)
            }
            Text(model.gapNote)
                .font(MoopType.detail)
                .foregroundStyle(Moop.ink.opacity(0.7))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, Space.cut)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.beat)
    }

    // MARK: calendar

    private var calendar: some View {
        VStack(alignment: .leading, spacing: Space.cut) {
            HStack {
                Button { model.step(-1) } label: {
                    Label("Earlier", systemImage: "chevron.left")
                        .font(MoopType.detail).foregroundStyle(Moop.violet)
                }
                Spacer()
                Button { model.step(1) } label: {
                    Label("Later", systemImage: "chevron.right")
                        .font(MoopType.detail).foregroundStyle(Moop.violet)
                }
            }
            Rectangle().fill(Moop.veil).frame(height: 1)

            HStack(spacing: 0) {
                ForEach(["M","T","W","T","F","S","S"], id: \.self) { d in
                    Text(d).font(MoopType.micro)
                        .foregroundStyle(Moop.violet)
                        .frame(maxWidth: .infinity)
                }
            }
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7),
                      spacing: Space.beat) {
                ForEach(model.grid) { cell in
                    dayCell(cell)
                }
            }
            Rectangle().fill(Moop.veil).frame(height: 1)
            Text(model.savedNote)
                .font(MoopType.detail)
                .foregroundStyle(Moop.ink.opacity(0.75))
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.beat)
    }

    @ViewBuilder
    private func dayCell(_ cell: HistoryViewModel.Cell) -> some View {
        if let date = cell.date {
            Button { model.open(cell) } label: {
                VStack(spacing: Space.dot) {
                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(MoopType.reading)
                        .foregroundStyle(Moop.ink)
                    if let mood = cell.mood {
                        Circle().fill(Moop.emotion(mood)).frame(width: 7, height: 7)
                    } else if cell.saved {
                        Circle().fill(Moop.ink.opacity(0.35)).frame(width: 7, height: 7)
                    } else {
                        Text("—").font(MoopType.micro).foregroundStyle(Moop.ink.opacity(0.3))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(cell.isToday ? Moop.citrus : .clear,
                            in: RoundedRectangle(cornerRadius: Edge.slight, style: .continuous))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(date.formatted(.dateTime.day().month(.wide)))
        } else {
            Color.clear.frame(height: 44)
        }
    }

    // MARK: month, week by week

    private var comparison: some View {
        VStack(alignment: .leading, spacing: Space.section) {
            ForEach(model.bands(for: model.anchor)) { band in
                VStack(alignment: .leading, spacing: Space.tick) {
                    HStack {
                        Text(band.label)
                            .font(MoopType.micro)
                            .foregroundStyle(Moop.ink)
                        Spacer()
                        Text(band.note)
                            .font(MoopType.detail)
                            .foregroundStyle(Moop.violet)
                    }
                    GeometryReader { geo in
                        HStack(spacing: Space.dot) {
                            ForEach(band.ribbons) { ribbon in
                                RoundedRectangle(cornerRadius: Edge.slight, style: .continuous)
                                    .fill(Moop.emotion(ribbon.mood))
                                    .frame(width: max(geo.size.width * ribbon.fraction - Space.dot, 12))
                            }
                        }
                    }
                    .frame(height: 27)
                }
            }

            if model.bands(for: model.anchor).isEmpty {
                Text("Nothing saved this month yet.")
                    .font(MoopType.reading)
                    .foregroundStyle(Moop.ink.opacity(0.6))
            }

            Button { open(.compare) } label: {
                Text(model.compareLabel)
                    .font(MoopType.detail)
                    .foregroundStyle(Moop.ink)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, Space.cut)
                    .frame(height: 34)
                    .background(Moop.citrus, in: RoundedRectangle(cornerRadius: Edge.slight, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, Space.gutter)
        .padding(.top, Space.beat)
    }
}
