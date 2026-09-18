import SwiftUI

// one token, both modes, resolved by the system. no forced colour scheme anywhere.
extension Color {
    init(light: UInt32, dark: UInt32) {
        self.init(uiColor: UIColor { trait in
            UIColor(rgb: trait.userInterfaceStyle == .dark ? dark : light)
        })
    }

    static let canvas       = Color(light: 0xF6F4EF, dark: 0x14130F)
    static let surface      = Color(light: 0xFFFFFF, dark: 0x1F1D19)
    static let hairline     = Color(light: 0xE4E0D6, dark: 0x33302A)
    static let inkPrimary   = Color(light: 0x1C1B18, dark: 0xF2EFE8)
    static let inkSecondary = Color(light: 0x5F5A50, dark: 0xA8A197)
    static let streakFlame  = Color(light: 0xB0602E, dark: 0xD4834E)
    static let danger       = Color(light: 0xB3412F, dark: 0xE06A54)

    // brandFill carries white labels, so in dark it only lightens far enough to
    // hold them. brandText is the brand colour for type and glyphs.
    static let brandFill    = Color(light: 0x3E6B54, dark: 0x4F8168)
    static let brandPressed = Color(light: 0x335844, dark: 0x3E6B54)
    static let brandText    = Color(light: 0x3E6B54, dark: 0x6E9C82)
    static let brandSoft    = Color(light: 0xE9EFEA, dark: 0x1E2A23)

    // the camera stays dark in both modes: a light surround changes how the
    // photo's exposure reads
    static let viewfinder   = Color(light: 0x0A0908, dark: 0x0A0908)
    static let onDark       = Color(light: 0xFFFFFF, dark: 0xFFFFFF)
}

private extension UIColor {
    convenience init(rgb: UInt32) {
        self.init(red: CGFloat((rgb >> 16) & 0xFF) / 255,
                  green: CGFloat((rgb >> 8) & 0xFF) / 255,
                  blue: CGFloat(rgb & 0xFF) / 255,
                  alpha: 1)
    }
}
