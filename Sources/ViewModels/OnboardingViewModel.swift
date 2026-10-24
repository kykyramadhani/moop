import Foundation
import Observation

@Observable
final class OnboardingViewModel {
    private let defaults = UserDefaults.standard

    var name: String = ""

    private var trimmed: String { name.trimmingCharacters(in: .whitespaces) }

    func finish() {
        defaults.set(trimmed.isEmpty ? "You" : trimmed, forKey: Prefs.name)
        defaults.set(true, forKey: Prefs.onboarded)
    }
}
