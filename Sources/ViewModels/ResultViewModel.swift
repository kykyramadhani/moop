import Observation
import UIKit

@Observable
final class ResultViewModel {
    private let reader: MoodReader
    private let snaps: SnapStore

    var rewording = false
    var showingWhy = false

    init(reader: MoodReader, snaps: SnapStore) {
        self.reader = reader
        self.snaps = snaps
    }

    var mood: Mood? { reader.result?.mood }
    var sentence: String? { reader.result?.sentence }
    var photo: UIImage? { reader.result?.photo }
    var because: String? { reader.result?.because }
    var failed: Bool { reader.isFailed }
    var position: String {
        let today = snaps.snaps(on: .now).count
        return "\(max(today, 1)) of \(max(today, 1))"
    }

    func retry() async {
        await reader.retry()
        if let result = reader.result {
            snaps.add(image: result.photo, mood: result.mood,
                      sentence: result.sentence, because: result.because)
        }
    }

    // the saved row has to follow the screen, or reopening the day shows the
    // wording the person just replaced
    func anotherLine() async {
        rewording = true
        defer { rewording = false }
        guard let fresh = await reader.reword(), let latest = snaps.snaps.first else { return }
        snaps.reword(latest, to: fresh)
    }
}
