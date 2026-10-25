import CloudKit
import Foundation
import Observation

// private iCloud sync, and only that. every moment becomes one record in a
// zone of the person's own private database. the engine does the retrying,
// batching and change tokens, so this file only says what a moment looks like
// and what to do when one arrives.
//
// ponytail: a moment's photo is never edited, only its sentence, so a
// conflict just takes the server's copy. add real merging if moments ever
// get more editable fields.
@Observable
final class CloudSync: CKSyncEngineDelegate {
    static let containerID = "iCloud.com.rizkyinsania.moop"

    private(set) var state: SyncState = .off
    private(set) var lastSynced: Date?

    private let snaps: SnapStore
    @ObservationIgnored private var engine: CKSyncEngine?
    @ObservationIgnored private let zone = CKRecordZone.ID(zoneName: "Moments")
    @ObservationIgnored private var failure: SyncState?
    @ObservationIgnored private var stopWhenSent = false
    @ObservationIgnored private let stateURL: URL

    // sync can end without the person asking: the iCloud account changed, or
    // everything was deleted. whoever owns the switch needs to know.
    @ObservationIgnored var onEnded: (() -> Void)?

    init(snaps: SnapStore) {
        self.snaps = snaps
        stateURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("cloud-state.json")
        try? FileManager.default.createDirectory(at: stateURL.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    static func availability() async -> CloudAvailability {
        switch try? await CKContainer(identifier: containerID).accountStatus() {
        case .available: .available
        case .noAccount: .notSignedIn
        case .restricted: .restricted
        case .temporarilyUnavailable: .temporarilyUnavailable
        default: .unknown
        }
    }

    // MARK: on and off

    func start() {
        guard engine == nil else { return }
        state = .preparing
        let saved = (try? Data(contentsOf: stateURL))
            .flatMap { try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: $0) }
        var config = CKSyncEngine.Configuration(
            database: CKContainer(identifier: Self.containerID).privateCloudDatabase,
            stateSerialization: saved, delegate: self)
        config.automaticallySync = true
        let engine = CKSyncEngine(config)
        self.engine = engine

        // the first time only: make the zone and queue what is already here.
        // after that the engine remembers its own queue across launches.
        if saved == nil {
            engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: zone))])
            engine.state.add(pendingRecordZoneChanges: snaps.snaps.map { .saveRecord(recordID($0.id)) })
        }
        snaps.didSave = { [weak self] id in self?.queue([id]) }
        snaps.didRemove = { [weak self] id in
            guard let self else { return }
            self.engine?.state.add(pendingRecordZoneChanges: [.deleteRecord(self.recordID(id))])
        }
        state = .pending
    }

    /// for moments that arrive without going through the store's own hooks,
    /// like a restored backup
    func queue(_ ids: [UUID]) {
        engine?.state.add(pendingRecordZoneChanges: ids.map { .saveRecord(recordID($0)) })
    }

    /// stops syncing and forgets the engine. nothing in iCloud is touched.
    func stop() {
        engine = nil
        snaps.didSave = nil
        snaps.didRemove = nil
        try? FileManager.default.removeItem(at: stateURL)
        failure = nil
        state = .off
    }

    /// removes the zone, which removes every moment in iCloud for every device,
    /// then stops once that has really been sent.
    func deleteEverywhere() {
        guard let engine else { return }
        snaps.didRemove = nil
        engine.state.add(pendingDatabaseChanges: [.deleteZone(zone)])
        snaps.wipeLocal()
        stopWhenSent = true
        Task { try? await engine.sendChanges() }
    }

    func retry() {
        failure = nil
        guard let engine else { start(); return }
        state = .pending
        Task { try? await engine.sendChanges(); try? await engine.fetchChanges() }
    }

    // MARK: delegate

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let update):
            // after stop() the engine is gone, and its last words must not
            // bring the file back
            if engine != nil, let data = try? JSONEncoder().encode(update.stateSerialization) { try? data.write(to: stateURL) }

        case .accountChange(let change):
            switch change.changeType {
            case .signIn: break
            // another account must never see this one's moments, and this one's
            // engine state means nothing to it. stop, keep the local copy.
            case .signOut, .switchAccounts:
                await MainActor.run { stop(); state = .unavailable; onEnded?() }
            @unknown default: break
            }

        case .fetchedDatabaseChanges(let changes):
            for gone in changes.deletions where gone.zoneID == zone {
                // deleted on purpose elsewhere: follow. anything else (purged,
                // encrypted data reset) is not a decision, so keep what is here.
                if gone.reason == .deleted {
                    await MainActor.run { snaps.wipeLocal() }
                } else {
                    await MainActor.run { stop(); state = .attention }
                }
            }

        case .fetchedRecordZoneChanges(let changes):
            await MainActor.run {
                for modification in changes.modifications { apply(modification.record) }
                for deletion in changes.deletions {
                    guard let id = UUID(uuidString: deletion.recordID.recordName) else { continue }
                    // a delete from elsewhere beats a save still waiting here, so
                    // a removed moment is not brought back to life
                    engine?.state.remove(pendingRecordZoneChanges: [.saveRecord(deletion.recordID)])
                    snaps.applyRemoteDelete(id)
                }
            }

        case .sentRecordZoneChanges(let sent):
            for failed in sent.failedRecordSaves { await handle(failed.error, record: failed.record, in: syncEngine) }

        case .willFetchChanges, .willSendChanges:
            failure = nil
            await MainActor.run { state = .syncing }

        case .didFetchChanges, .didSendChanges:
            await settle(syncEngine)

        default: break
        }
    }

    func nextRecordZoneChangeBatch(_ context: CKSyncEngine.SendChangesContext,
                                   syncEngine: CKSyncEngine) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = syncEngine.state.pendingRecordZoneChanges.filter { context.options.scope.contains($0) }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending) { id in
            await MainActor.run { self.record(for: id) }
        }
    }

    // MARK: mapping

    private func recordID(_ id: UUID) -> CKRecord.ID { CKRecord.ID(recordName: id.uuidString, zoneID: zone) }

    // a record that cannot be built (photo gone from disk) is dropped from the
    // queue by the engine rather than retried forever
    private func record(for id: CKRecord.ID) -> CKRecord? {
        guard let uuid = UUID(uuidString: id.recordName),
              let snap = snaps.snaps.first(where: { $0.id == uuid }) else { return nil }
        let record = CKRecord(recordType: "Moment", recordID: id)
        record["date"] = snap.date
        record["mood"] = snap.mood
        record["sentence"] = snap.sentence
        record["because"] = snap.because
        record["photo"] = CKAsset(fileURL: snaps.photoURL(for: snap))
        return record
    }

    private func apply(_ record: CKRecord) {
        guard let id = UUID(uuidString: record.recordID.recordName),
              let date = record["date"] as? Date else { return }
        let snap = Snap(id: id, date: date, mood: record["mood"] as? String ?? "",
                        sentence: record["sentence"] as? String, because: record["because"] as? String)
        snaps.applyRemote(snap, photo: (record["photo"] as? CKAsset)?.fileURL)
    }

    // MARK: outcomes

    private func handle(_ error: CKError, record: CKRecord, in engine: CKSyncEngine) async {
        switch error.code {
        case .serverRecordChanged:
            if let server = error.serverRecord { await MainActor.run { apply(server) } }
            engine.state.remove(pendingRecordZoneChanges: [.saveRecord(record.recordID)])
        case .zoneNotFound:
            engine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: zone))])
            engine.state.add(pendingRecordZoneChanges: [.saveRecord(record.recordID)])
        case .unknownItem:
            engine.state.remove(pendingRecordZoneChanges: [.saveRecord(record.recordID)])
        case .quotaExceeded:
            failure = .full
        case .networkUnavailable, .networkFailure:
            failure = .offline
        case .notAuthenticated:
            failure = .unavailable
        default:
            failure = .attention
        }
    }

    // "up to date" is only ever said after a send that left nothing waiting and
    // nothing failed. anything else says what it is.
    private func settle(_ engine: CKSyncEngine) async {
        let waiting = !engine.state.pendingRecordZoneChanges.isEmpty || !engine.state.pendingDatabaseChanges.isEmpty
        await MainActor.run {
            if let failure { state = failure }
            else if waiting { state = .pending }
            else {
                state = .upToDate
                lastSynced = .now
                if stopWhenSent { stopWhenSent = false; stop(); onEnded?() }
            }
        }
    }
}
