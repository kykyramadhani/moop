import FoundationModels

@Generable
enum Mood: String, CaseIterable {
    case calm, adventure, homey, playful, mystery

    var display: String { rawValue.capitalized }
}
