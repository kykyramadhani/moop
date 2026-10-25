import Foundation

// where moments live. local never leaves the phone. apple means the person
// signed in and may turn on private iCloud sync, which is a separate switch.
enum StorageMode: String {
    case localOnly, appleCloud

    var label: String { self == .localOnly ? "On this iPhone" : "Apple & iCloud" }
}

// signing in and having iCloud are two facts. one never implies the other.
enum AuthState { case guest, appleSignedIn, reauthRequired }

enum CloudAvailability {
    case available, notSignedIn, restricted, temporarilyUnavailable, unknown

    var explanation: String {
        switch self {
        case .available: "iCloud is ready."
        case .notSignedIn: "Sign in to iCloud in the iPhone Settings app to sync."
        case .restricted: "iCloud is restricted on this iPhone."
        case .temporarilyUnavailable: "iCloud is not reachable right now. Try again in a moment."
        case .unknown: "moop could not check iCloud."
        }
    }
}

enum SyncState: Equatable {
    case off, preparing, pending, syncing, upToDate, offline, unavailable, full, attention

    var label: String {
        switch self {
        case .off: "Off"
        case .preparing: "Preparing your moments…"
        case .pending: "Waiting to sync"
        case .syncing: "Syncing"
        case .upToDate: "Up to date"
        case .offline: "Sync paused — no connection"
        case .unavailable: "iCloud unavailable"
        case .full: "iCloud storage full"
        case .attention: "Sync needs attention"
        }
    }
}
