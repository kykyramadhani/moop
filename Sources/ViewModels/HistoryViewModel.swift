import Foundation
import Observation
import SwiftUI

@Observable
final class HistoryViewModel {
    enum Lens: String, CaseIterable { case week, calendar, month }

    private let snaps: SnapStore
    private let cal = Calendar.current

    var lens: Lens = .week
    var anchor: Date = .now
    var openDay: Date?

    init(snaps: SnapStore) { self.snaps = snaps }

    // MARK: headings

    var headline: String {
        switch lens {
        case .week: "How did this\nweek feel?"
        case .calendar: "Every day\nhas a place."
        case .month: "Month\nto month."
        }
    }

    var rangeLabel: String {
        switch lens {
        case .week:
            let days = snaps.snaps(inWeekOf: anchor)
            guard let a = days.first, let b = days.last else { return "" }
            return "\(a.formatted(.dateTime.month(.abbreviated).day()))–\(b.formatted(.dateTime.day()))"
        case .calendar, .month:
            return anchor.formatted(.dateTime.month(.wide).year())
        }
    }

    // MARK: week

    struct WeekRow: Identifiable {
        let id: Date
        let date: Date
        let mood: Mood?
        let line: String
        var stamp: String { date.formatted(.dateTime.weekday(.abbreviated).day()) }
    }

    var week: [WeekRow] {
        snaps.snaps(inWeekOf: anchor).reversed().map { day in
            let shots = snaps.snaps(on: day)
            let first = shots.first
            return WeekRow(id: day, date: day, mood: first?.moodCase,
                           line: first?.sentence ?? (shots.isEmpty ? "nothing saved" : "kept without a word"))
        }
    }

    // MARK: calendar

    struct Cell: Identifiable {
        let id: Int
        let date: Date?
        let mood: Mood?
        let saved: Bool
        let isToday: Bool
    }

    var grid: [Cell] {
        guard let monthStart = cal.date(from: cal.dateComponents([.year, .month], from: anchor))
        else { return [] }
        // monday first, which is how the design reads left to right
        let shift = (cal.component(.weekday, from: monthStart) + 5) % 7
        return (0..<42).map { index in
            guard index >= shift,
                  let date = cal.date(byAdding: .day, value: index - shift, to: monthStart),
                  cal.isDate(date, equalTo: monthStart, toGranularity: .month)
            else { return Cell(id: index, date: nil, mood: nil, saved: false, isToday: false) }
            let shots = snaps.snaps(on: date)
            return Cell(id: index, date: date, mood: shots.first?.moodCase,
                        saved: !shots.isEmpty, isToday: cal.isDateInToday(date))
        }
    }

    var savedCount: Int { grid.filter(\.saved).count }

    // MARK: month, week by week

    struct Band: Identifiable {
        let id: String
        let label: String
        let note: String
        let ribbons: [Share]
    }

    // each week of the month becomes one row of ribbons, widths in proportion
    // to how much of that week felt each way
    func bands(for month: Date) -> [Band] {
        let days = snaps.days(inMonthOf: month)
        guard !days.isEmpty else { return [] }
        var bands: [Band] = []
        for start in stride(from: 0, to: days.count, by: 7) {
            let slice = Array(days[start ..< min(start + 7, days.count)])
            var counts: [Mood: Int] = [:]
            for day in slice {
                for snap in snaps.snaps(on: day) {
                    guard let mood = snap.moodCase else { continue }
                    counts[mood, default: 0] += 1
                }
            }
            let total = counts.values.reduce(0, +)
            guard total > 0, let first = slice.first, let last = slice.last else { continue }
            let ribbons = Mood.allCases.compactMap { mood -> Share? in
                guard let n = counts[mood], n > 0 else { return nil }
                return Share(id: "\(mood.rawValue)-\(first.timeIntervalSince1970)",
                             mood: mood, count: n, fraction: Double(n) / Double(total))
            }
            let dominant = counts.max { $0.value < $1.value }?.key
            bands.append(Band(
                id: "\(first.timeIntervalSince1970)",
                label: (first.formatted(.dateTime.month(.abbreviated).day()) + "—"
                        + last.formatted(.dateTime.day())).uppercased(),
                note: dominant.map { "mostly \($0.rawValue)" } ?? "",
                ribbons: ribbons))
        }
        return bands
    }

    var monthHeadline: String {
        let counts = snaps.moodCounts(inMonthOf: anchor)
        guard let top = counts.max(by: { $0.value < $1.value })?.key else {
            return "\(monthName(anchor))\nis still open."
        }
        return "\(monthName(anchor))\nwas mostly \(top.rawValue)."
    }

    var compareLabel: String { "Compare with \(monthName(previousMonth))  →" }

    // MARK: month to month

    struct Share: Identifiable {
        let id: String
        let mood: Mood
        let count: Int
        let fraction: Double
    }

    func shares(for month: Date) -> [Share] {
        let counts = snaps.moodCounts(inMonthOf: month)
        let total = max(counts.values.reduce(0, +), 1)
        return Mood.allCases.compactMap { mood in
            guard let n = counts[mood], n > 0 else { return nil }
            return Share(id: "\(mood.rawValue)-\(month.timeIntervalSince1970)",
                         mood: mood, count: n, fraction: Double(n) / Double(total))
        }
    }

    var previousMonth: Date { cal.date(byAdding: .month, value: -1, to: anchor) ?? anchor }
    func monthName(_ d: Date) -> String { d.formatted(.dateTime.month(.wide)) }

    // MARK: moving about

    func step(_ months: Int) {
        guard let next = cal.date(byAdding: .month, value: months, to: anchor) else { return }
        withAnimation(.easeOut(duration: 0.2)) { anchor = next }
    }

    func stepWeek(_ weeks: Int) {
        guard let next = cal.date(byAdding: .weekOfYear, value: weeks, to: anchor) else { return }
        withAnimation(.easeOut(duration: 0.2)) { anchor = next }
    }

    func open(_ cell: Cell) {
        guard cell.saved, let date = cell.date else { return }
        openDay = date
    }

    func open(_ row: WeekRow) {
        guard !snaps.snaps(on: row.date).isEmpty else { return }
        openDay = row.date
    }

    func dayModel(for day: Date) -> DayViewModel { DayViewModel(day: day, snaps: snaps) }

    var gapNote: String { "A gap is part of the story, too." }
    var savedNote: String { "\(savedCount) days saved  ·  1 quiet gap doesn't erase anything" }
}
