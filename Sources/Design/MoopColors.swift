import SwiftUI

// the rebuild palette. daylight and night are the two modes, resolved by the
// system from one token.
extension Color {
    init(day: UInt32, night: UInt32) {
        self.init(uiColor: UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? night : day)
        })
    }
}

enum Moop {
    static let canvas     = Color(day: 0xEDE9FF, night: 0x151A42)
    static let veil       = Color(day: 0xDCD5FA, night: 0x373D71)
    static let highlight  = Color(day: 0xF9F6FF, night: 0x333C72)
    static let scene      = Color(day: 0x29336E, night: 0x0E1433)

    static let ink        = Color(day: 0x171D48, night: 0xF0EDFF)
    static let onDark     = Color(day: 0xEDE9FF, night: 0xF0EDFF)
    static let onAccent   = Color(day: 0x18205A, night: 0x18205A)
    // violet is deep by day and pale by night, so what sits on it has to flip
    static let onViolet   = Color(day: 0xF0EDFF, night: 0x18205A)

    static let violet     = Color(day: 0x6745CA, night: 0xBCADFF)
    static let blue       = Color(day: 0x3154CF, night: 0x89A3FF)
    static let citrus     = Color(day: 0xC6F36B, night: 0xD4F783)
    static let alert      = Color(day: 0xA51F4C, night: 0xFF7399)

    // the camera is its own world and ignores the theme
    static let pureBlack  = Color(day: 0x000000, night: 0x000000)
    static let pill       = Color(day: 0x18181A, night: 0x18181A)

    static func emotion(_ mood: Mood) -> Color {
        switch mood {
        case .calm:      Color(day: 0xB4C9EF, night: 0x7F9FD1)
        case .adventure: Color(day: 0xA4DDA7, night: 0x89C797)
        case .homey:     Color(day: 0xEFAA8D, night: 0xF1AB92)
        case .playful:   Color(day: 0xFFCE66, night: 0xFFD985)
        case .mystery:   Color(day: 0xB6B2CA, night: 0xBAB8D3)
        }
    }
}

private extension UIColor {
    convenience init(hex: UInt32) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: 1)
    }
}
