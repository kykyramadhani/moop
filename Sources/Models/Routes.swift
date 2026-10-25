import Foundation

enum TodayRoute: Hashable {
    case result
    case explanation
    case streak
}

enum HistoryRoute: Hashable {
    case day(Date)
    /// carries the month you were looking at, so compare lines up with it
    case compare(Date)
}
