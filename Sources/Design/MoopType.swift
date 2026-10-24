import SwiftUI

// instrument serif for the display lines, dm sans for everything else.
// if the files are not bundled yet the system serif and sans stand in, so the
// layout is right either way. drop the ttfs in Support/Fonts to upgrade.
enum MoopType {
    static let poster    = serif(52)
    static let line      = serif(38)
    static let title     = sans(26, "Bold", .bold)
    static let moodWord  = sans(21, "Bold", .bold)
    static let statement = sans(18, "Medium", .medium)
    static let reading   = sans(16, "Regular", .regular)
    static let detail    = sans(13, "Medium", .medium)
    static let micro     = sans(11, "SemiBold", .semibold)

    private static func serif(_ size: CGFloat) -> Font {
        UIFont(name: "InstrumentSerif-Regular", size: size) != nil
            ? .custom("InstrumentSerif-Regular", fixedSize: size)
            : .system(size: size * 0.86, weight: .regular, design: .serif)
    }

    private static func sans(_ size: CGFloat, _ cut: String, _ weight: Font.Weight) -> Font {
        let name = "DMSans-\(cut)"
        return UIFont(name: name, size: size) != nil
            ? .custom(name, fixedSize: size)
            : .system(size: size, weight: weight)
    }
}
