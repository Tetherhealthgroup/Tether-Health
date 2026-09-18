import Flutter
import Foundation

/// The iOS half of the shell's key/value contract.
///
/// Backed by `UserDefaults.standard` — the app's own container — and not by the
/// Unplug App Group. That is a deliberate boundary, not an oversight. The App
/// Group exists because `DeviceActivityMonitor`, `ShieldConfiguration` and
/// `ShieldAction` run in three separate processes and genuinely need to read
/// the module's tier and override counts. Nothing in this store is theirs: it
/// is the shell's enrolments, the person's answers and their lapse history.
/// Putting it in the group would hand three extensions readable access to a
/// record of which health programmes somebody is enrolled in, in exchange for
/// nothing at all, and the widest surface is the one that gets audited.
///
/// If an extension ever does need a value from here, the right move is to copy
/// that one value into the group, not to move this store into it.
///
/// The methods are synchronous because the contract is. `UserDefaults` is a
/// memory-backed cache after first touch and flushes on its own schedule, so
/// there is nothing here worth suspending a channel call for.
final class TetherStore: NSObject, TetherStoreApi {

    /// Everything this store writes is prefixed, so `clear()` can be honest
    /// about what it owns. `UserDefaults.standard` for the Runner also holds
    /// keys written by Flutter itself and by the system, and a wipe that took
    /// those with it would be a deletion feature that logs people out of
    /// unrelated things.
    private static let prefix = "tether.store."

    private let defaults: UserDefaults

    init(binaryMessenger: FlutterBinaryMessenger, defaults: UserDefaults = .standard) {
        self.defaults = defaults
        super.init()
        TetherStoreApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)
    }

    func read(key: String) throws -> String? {
        defaults.string(forKey: Self.prefix + key)
    }

    func write(key: String, value: String) throws {
        defaults.set(value, forKey: Self.prefix + key)
    }

    func remove(key: String) throws {
        defaults.removeObject(forKey: Self.prefix + key)
    }

    /// Removes every key this store owns.
    ///
    /// Called by the `export_and_delete` hard delete, which promises the record
    /// is gone rather than hidden. It enumerates rather than removing one known
    /// key so that a second key added later is covered without anybody having
    /// to remember to extend the delete path — the failure mode of a selective
    /// wipe is that it keeps looking correct while it stops being complete.
    func clear() throws {
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix(Self.prefix) {
            defaults.removeObject(forKey: key)
        }
    }
}
