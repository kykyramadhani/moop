import Foundation

enum TodayRoute: Hashable {
    case result
    case explanation
    case streak
}

enum HistoryRoute: Hashable {
    case day(Date)
    case compare
}
