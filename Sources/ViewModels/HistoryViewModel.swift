import SwiftUI

@Observable
final class HistoryViewModel {
    private let snaps: SnapStore
    private let calendar = Calendar.current
    private let defaults = UserDefaults.standard

    // 0 is this month, 1 the one before it, back as far as the first snap
    private(set) var monthsBack = 0
    private(set) var drag: CGFloat = 0
    var openDay: Date?

    init(snaps: SnapStore) { self.snaps = snaps }

    // MARK: what the screen shows

    var title: String { monthStart.formatted(.dateTime.month(.wide).year()) }
    var isEmpty: Bool { snaps.snaps.isEmpty }
    var total: Int { snaps.snaps.count }
    var streak: Int { snaps.streak }
    var canPageBack: Bool { monthsBack < monthsAvailable }
    var canPageForward: Bool { monthsBack > 0 }
    var tilt: Double { drag / 60 }

    // the grid asks for a square at a time, so nothing is loaded off screen
    func cell(at index: Int) -> DayCell? {
        guard let date = date(at: index) else { return nil }
        let shots = snaps.snaps(on: date)
        return DayCell(date: date,
                       image: shots.first.flatMap { snaps.image(for: $0) },
                       count: shots.count,
                       isToday: calendar.isDateInToday(date))
    }

    // the sheet's model is made here so the view never sees the store
    func dayModel(for day: Date) -> DayViewModel {
        DayViewModel(day: day, snaps: snaps)
    }

    func open(_ cell: DayCell) {
        guard cell.count > 0 else { return }
        openDay = cell.date
    }

    // MARK: months

    private var monthStart: Date {
        let thisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        return calendar.date(byAdding: .month, value: -monthsBack, to: thisMonth) ?? thisMonth
    }

    // nothing to look at before the first snap, so that is the floor
    private var monthsAvailable: Int {
        guard let oldest = snaps.snaps.map(\.date).min() else { return 0 }
        let from = calendar.date(from: calendar.dateComponents([.year, .month], from: oldest)) ?? .now
        let to = calendar.date(from: calendar.dateComponents([.year, .month], from: .now)) ?? .now
        return max(0, calendar.dateComponents([.month], from: from, to: to).month ?? 0)
    }

    private func date(at index: Int) -> Date? {
        let offset = calendar.component(.weekday, from: monthStart) - 1
        let day = index - offset
        guard day >= 0,
              let date = calendar.date(byAdding: .day, value: day, to: monthStart),
              calendar.isDate(date, equalTo: monthStart, toGranularity: .month) else { return nil }
        return date
    }

    // MARK: paging

    // only a clearly sideways drag counts, so the vertical scroll underneath
    // keeps working
    func dragChanged(_ translation: CGSize) {
        guard abs(translation.width) > abs(translation.height) else { return }
        drag = translation.width
    }

    func dragEnded(_ translation: CGSize) {
        let width = translation.width
        guard abs(width) > abs(translation.height) else { return settle() }
        // dragging right pulls the earlier month in from the left
        if width > 80, canPageBack { page(by: 1) }
        else if width < -80, canPageForward { page(by: -1) }
        else { settle() }
    }

    // one peek toward the stack on first open, so the gesture is visible without
    // being spelled out. stops for good once a month has actually been paged.
    func hint() async {
        guard !defaults.bool(forKey: Prefs.pagedMonths), monthsAvailable > 0 else { return }
        try? await Task.sleep(for: .milliseconds(650))
        withAnimation(.easeOut(duration: 0.28)) { drag = 26 }
        try? await Task.sleep(for: .milliseconds(300))
        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { drag = 0 }
    }

    private func settle() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { drag = 0 }
    }

    // out one way and in from the other, so the month is seen to be replaced
    private func page(by step: Int) {
        defaults.set(true, forKey: Prefs.pagedMonths)
        let away: CGFloat = step > 0 ? 440 : -440
        withAnimation(.easeOut(duration: 0.18)) { drag = away }
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(180))
            // the jump to the far side must not animate, or swiftui folds it into
            // the slide back and the card returns the way it left
            var jump = Transaction()
            jump.disablesAnimations = true
            withTransaction(jump) {
                monthsBack += step
                drag = -away
            }
            try? await Task.sleep(for: .milliseconds(16))
            withAnimation(.spring(response: 0.34, dampingFraction: 0.85)) { drag = 0 }
        }
    }
}
