import SwiftUI

extension Mood {
    // in light the field is tinted and the word is ink. in dark the field goes
    // almost neutral and the word carries the mood instead: five tinted dark
    // fields collapse into two browns and two blue-blacks.
    var field: (top: Color, bottom: Color) {
        switch self {
        case .calm:      (Color(light: 0xDDE7E0, dark: 0x161A17), Color(light: 0xC9D9CF, dark: 0x10130F))
        case .adventure: (Color(light: 0xDBE3EC, dark: 0x15181E), Color(light: 0xC5D3E1, dark: 0x0F1219))
        case .homey:     (Color(light: 0xEDE4D6, dark: 0x1A1713), Color(light: 0xDED1BC, dark: 0x14110D))
        case .playful:   (Color(light: 0xF0E3DB, dark: 0x1B1613), Color(light: 0xE3CFC3, dark: 0x15100E))
        case .mystery:   (Color(light: 0xE3E1EA, dark: 0x17161C), Color(light: 0xD0CDDB, dark: 0x121117))
        }
    }

    var ink: Color {
        switch self {
        case .calm:      Color(light: 0x1C1B18, dark: 0x9FCBB1)
        case .adventure: Color(light: 0x1C1B18, dark: 0xA8C4E8)
        case .homey:     Color(light: 0x1C1B18, dark: 0xE3C89A)
        case .playful:   Color(light: 0x1C1B18, dark: 0xEEB39C)
        case .mystery:   Color(light: 0x1C1B18, dark: 0xC2BCDE)
        }
    }
}
