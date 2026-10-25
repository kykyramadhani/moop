import CryptoKit
import Foundation
import ZIPFoundation

// a backup is one zip: manifest.json, index.json and photos/<id>.jpg. the
// manifest lists a checksum per photo so a damaged file is refused before it
// touches anything.
struct BackupManifest: Codable {
    var version = 1
    var createdAt: Date
    var appVersion: String
    var count: Int
    var name: String?
    var theme: String?
    var photos: [String: String]
}

enum BackupError: LocalizedError {
    case unreadable, newerThanThisApp, damaged

    var errorDescription: String? {
        switch self {
        case .unreadable: "That file is not a moop backup."
        case .newerThanThisApp: "This backup was made by a newer version of moop. Update the app and try again."
        case .damaged: "This backup is damaged, so nothing was changed."
        }
    }
}

// a backup that has been opened and checked but not yet merged. the person
// sees the numbers first, then decides.
struct RestoreJob {
    let manifest: BackupManifest
    let rows: [Snap]
    let photos: URL
    fileprivate let staging: URL

    func newCount(in store: SnapStore) -> Int { rows.filter { !store.has($0.id) }.count }
    func discard() { try? FileManager.default.removeItem(at: staging) }
}

enum BackupService {
    private static let fm = FileManager.default

    static func make(from store: SnapStore, name: String?, theme: String?) throws -> URL {
        let rows = store.snaps.filter { fm.fileExists(atPath: store.photoURL(for: $0).path) }
        let stage = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let photos = stage.appendingPathComponent("photos", isDirectory: true)
        try fm.createDirectory(at: photos, withIntermediateDirectories: true)
        defer { try? fm.removeItem(at: stage) }

        var sums: [String: String] = [:]
        for row in rows {
            let source = store.photoURL(for: row)
            let file = "\(row.id).jpg"
            // a hard link costs no disk. falls back to a copy if the volume says no.
            if (try? fm.linkItem(at: source, to: photos.appendingPathComponent(file))) == nil {
                try fm.copyItem(at: source, to: photos.appendingPathComponent(file))
            }
            sums[file] = try checksum(of: source)
        }
        let manifest = BackupManifest(
            createdAt: .now,
            appVersion: Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1",
            count: rows.count, name: name, theme: theme, photos: sums)
        try encoder.encode(manifest).write(to: stage.appendingPathComponent("manifest.json"))
        try encoder.encode(rows).write(to: stage.appendingPathComponent("index.json"))

        let zip = fm.temporaryDirectory
            .appendingPathComponent("moop-backup-\(Date.now.formatted(.iso8601.year().month().day())).zip")
        try? fm.removeItem(at: zip)
        try fm.zipItem(at: stage, to: zip, shouldKeepParent: false, compressionMethod: .none)

        // read it back before calling it a backup. a zip that cannot be opened
        // is not one.
        let check = try Archive(url: zip, accessMode: .read)
        guard check["manifest.json"] != nil, check["index.json"] != nil,
              check.filter({ $0.path.hasPrefix("photos/") && $0.type == .file }).count == rows.count
        else { throw BackupError.damaged }
        return zip
    }

    static func open(_ zip: URL) throws -> RestoreJob {
        guard let archive = try? Archive(url: zip, accessMode: .read) else { throw BackupError.unreadable }
        // paths are only ever looked up by name below, never used as a
        // destination, but a zip trying to climb out is not worth reading
        for entry in archive where entry.path.hasPrefix("/") || entry.path.split(separator: "/").contains("..") {
            throw BackupError.damaged
        }
        guard let manifest: BackupManifest = try read("manifest.json", from: archive) else { throw BackupError.unreadable }
        guard manifest.version <= 1 else { throw BackupError.newerThanThisApp }
        guard let rows: [Snap] = try read("index.json", from: archive) else { throw BackupError.unreadable }

        let stage = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
        let photos = stage.appendingPathComponent("photos", isDirectory: true)
        try fm.createDirectory(at: photos, withIntermediateDirectories: true)
        do {
            for row in rows {
                let file = "\(row.id).jpg"
                guard let entry = archive["photos/\(file)"], let want = manifest.photos[file] else { throw BackupError.damaged }
                let target = photos.appendingPathComponent(file)
                _ = try archive.extract(entry, to: target)
                guard try checksum(of: target) == want else { throw BackupError.damaged }
            }
        } catch {
            try? fm.removeItem(at: stage)
            throw error is BackupError ? error : BackupError.damaged
        }
        return RestoreJob(manifest: manifest, rows: rows, photos: photos, staging: stage)
    }

    private static func read<T: Decodable>(_ path: String, from archive: Archive) throws -> T? {
        guard let entry = archive[path] else { return nil }
        var data = Data()
        _ = try archive.extract(entry) { data.append($0) }
        return try? decoder.decode(T.self, from: data)
    }

    private static func checksum(of url: URL) throws -> String {
        SHA256.hash(data: try Data(contentsOf: url, options: .mappedIfSafe))
            .map { String(format: "%02x", $0) }.joined()
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        return e
    }()
    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }()
}

#if DEBUG
import UIKit

extension BackupService {
    // restore is the one place that can quietly eat a person's history, so
    // this runs at launch: round trip, a second import, and a damaged file.
    static func check() {
        let fm = FileManager.default
        let root = fm.temporaryDirectory.appendingPathComponent("backup-check-\(UUID().uuidString)")
        defer { try? fm.removeItem(at: root) }
        let a = SnapStore(folder: root.appendingPathComponent("a"))
        let b = SnapStore(folder: root.appendingPathComponent("b"))
        for i in 0..<3 {
            let image = UIGraphicsImageRenderer(size: CGSize(width: 40, height: 40)).image {
                UIColor(hue: CGFloat(i) / 3, saturation: 1, brightness: 1, alpha: 1).setFill()
                $0.fill(CGRect(x: 0, y: 0, width: 40, height: 40))
            }
            a.add(image: image, mood: i == 2 ? nil : .calm, sentence: i == 2 ? nil : "line \(i)")
        }

        do {
            let zip = try make(from: a, name: "Check", theme: nil)
            let job = try open(zip)
            assert(job.rows.count == 3 && job.newCount(in: b) == 3, "backup: wrong count")
            assert(b.merge(job.rows, photos: job.photos) == 3, "backup: first restore")
            assert(b.merge(job.rows, photos: job.photos) == 0, "backup: second restore added duplicates")
            assert(b.snaps.count == 3, "backup: duplicates after restore")
            for snap in a.snaps {
                let same = try Data(contentsOf: a.photoURL(for: snap)) == Data(contentsOf: b.photoURL(for: snap))
                assert(same, "backup: photo bytes changed")
            }
            job.discard()

            var bytes = try Data(contentsOf: zip)
            bytes[bytes.count / 2] ^= 0xFF
            let broken = root.appendingPathComponent("broken.zip")
            try bytes.write(to: broken)
            assert((try? open(broken)) == nil, "backup: a damaged file was accepted")

            let junk = root.appendingPathComponent("junk.zip")
            try Data("not a zip".utf8).write(to: junk)
            assert((try? open(junk)) == nil, "backup: junk was accepted")
            print("[moop] backup check ok")
        } catch {
            assertionFailure("backup check threw \(error)")
        }
    }
}
#endif
