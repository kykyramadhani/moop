import SwiftUI

enum Theme: String, CaseIterable {
    case system, light, dark

    var label: String { rawValue.capitalized }

    var scheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}
