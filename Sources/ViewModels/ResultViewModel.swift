import Observation
import UIKit

@Observable
final class ResultViewModel {
    private let reader: MoodReader
    private let snaps: SnapStore
    private let navigator: Navigator

    var rewording = false

    init(reader: MoodReader, snaps: SnapStore, navigator: Navigator) {
        self.reader = reader
        self.snaps = snaps
        self.navigator = navigator
    }

    var mood: Mood? { reader.result?.mood }
    var sentence: String? { reader.result?.sentence }
    var photo: UIImage? { reader.result?.photo }

    // the saved row has to follow the screen, or reopening the day shows the
    // wording the person just replaced
    func reword() async {
        rewording = true
        defer { rewording = false }
        guard let fresh = await reader.reword(), let latest = snaps.snaps.first else { return }
        snaps.reword(latest, to: fresh)
    }

    func again() {
        reader.reset()
        navigator.home()
    }
}
