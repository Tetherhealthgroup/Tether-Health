import Foundation

/// The App Group container the app and its three extensions share.
///
/// Addendum §2.1: `DeviceActivityMonitor`, `ShieldConfiguration` and
/// `ShieldAction` each run in their own process with a very tight memory budget
/// and no Flutter. The only thing they share with the app is this container, so
/// tier state, module configuration and override counts live here and nowhere
/// else. A value that is not in here does not exist as far as an extension is
/// concerned.
///
/// The suite name must match the App Group capability on all four targets. If
/// it ever diverges, the extensions silently read defaults and the intercept
/// starts behaving as though the person were on tier 0 — so [isConfigured]
/// exists and screen I reports it.
public enum UnplugSharedState {

    /// Must match the App Group on the Runner and all three extension targets.
    public static let appGroup = "group.com.TetherHealthLLC.tetherhealth.unplug"

    private static let defaults = UserDefaults(suiteName: appGroup)

    private enum Key {
        static let tier = "tier"
        static let overrideAllowance = "overrideAllowance"
        static let overridesUsed = "overridesUsed"
        static let gate = "gate"
        static let strict = "strict"
        static let groupLabels = "groupLabels"
        static let totalApps = "totalApps"
        static let sessionEndsAt = "sessionEndsAt"
        static let sessionCoversEverything = "sessionCoversEverything"
        static let passUntil = "passUntil"
        static let scheduleActive = "scheduleActive"
        static let authorizationRequested = "authorizationRequested"
        static let shieldEvents = "shieldEvents"
        static let dismissEvents = "dismissEvents"
        static let lastThresholdMinutes = "lastThresholdMinutes"
        static let pendingEvents = "pendingEvents"
    }

    /// False when the App Group is missing or misconfigured on this build.
    public static var isConfigured: Bool { defaults != nil }

    // MARK: - Module configuration

    public static var tier: Int {
        get { defaults?.integer(forKey: Key.tier) ?? 0 }
        set { defaults?.set(newValue, forKey: Key.tier) }
    }

    public static var overrideAllowance: Int {
        get { defaults?.object(forKey: Key.overrideAllowance) as? Int ?? 3 }
        set { defaults?.set(newValue, forKey: Key.overrideAllowance) }
    }

    public static var overridesUsed: Int {
        get { defaults?.integer(forKey: Key.overridesUsed) ?? 0 }
        set { defaults?.set(newValue, forKey: Key.overridesUsed) }
    }

    public static var overridesLeft: Int {
        max(0, overrideAllowance - overridesUsed)
    }

    /// One of `none`, `breath`, `commitment`, `puzzle`.
    public static var gate: String {
        get { defaults?.string(forKey: Key.gate) ?? "none" }
        set { defaults?.set(newValue, forKey: Key.gate) }
    }

    public static var strict: Bool {
        get { defaults?.bool(forKey: Key.strict) ?? false }
        set { defaults?.set(newValue, forKey: Key.strict) }
    }

    /// The labels the person gave their groups — the only names iOS allows.
    public static var groupLabels: [String] {
        get { defaults?.stringArray(forKey: Key.groupLabels) ?? [] }
        set { defaults?.set(newValue, forKey: Key.groupLabels) }
    }

    public static var totalApps: Int {
        get { defaults?.integer(forKey: Key.totalApps) ?? 0 }
        set { defaults?.set(newValue, forKey: Key.totalApps) }
    }

    public static var authorizationRequested: Bool {
        get { defaults?.bool(forKey: Key.authorizationRequested) ?? false }
        set { defaults?.set(newValue, forKey: Key.authorizationRequested) }
    }

    public static var scheduleActive: Bool {
        get { defaults?.bool(forKey: Key.scheduleActive) ?? false }
        set { defaults?.set(newValue, forKey: Key.scheduleActive) }
    }

    // MARK: - Session and passes

    public static var sessionEndsAt: Date? {
        get {
            let seconds = defaults?.double(forKey: Key.sessionEndsAt) ?? 0
            return seconds > 0 ? Date(timeIntervalSince1970: seconds) : nil
        }
        set {
            defaults?.set(newValue?.timeIntervalSince1970 ?? 0, forKey: Key.sessionEndsAt)
        }
    }

    public static var sessionCoversEverything: Bool {
        get { defaults?.bool(forKey: Key.sessionCoversEverything) ?? false }
        set { defaults?.set(newValue, forKey: Key.sessionCoversEverything) }
    }

    /// Until when the shield stays lifted after a gate or an override.
    public static var passUntil: Date? {
        get {
            let seconds = defaults?.double(forKey: Key.passUntil) ?? 0
            return seconds > 0 ? Date(timeIntervalSince1970: seconds) : nil
        }
        set { defaults?.set(newValue?.timeIntervalSince1970 ?? 0, forKey: Key.passUntil) }
    }

    /// How long a cleared gate or an override keeps the shield down.
    public static let passDuration: TimeInterval = 5 * 60

    public static func grantPass(from now: Date = Date()) {
        passUntil = now.addingTimeInterval(passDuration)
    }

    public static func shieldLifted(at now: Date = Date()) -> Bool {
        guard let until = passUntil else { return false }
        return until > now
    }

    // MARK: - Counters the app cannot observe directly

    public static var shieldEvents: Int {
        get { defaults?.integer(forKey: Key.shieldEvents) ?? 0 }
        set { defaults?.set(newValue, forKey: Key.shieldEvents) }
    }

    public static var dismissEvents: Int {
        get { defaults?.integer(forKey: Key.dismissEvents) ?? 0 }
        set { defaults?.set(newValue, forKey: Key.dismissEvents) }
    }

    public static var lastThresholdMinutes: Int {
        get { defaults?.integer(forKey: Key.lastThresholdMinutes) ?? 0 }
        set { defaults?.set(newValue, forKey: Key.lastThresholdMinutes) }
    }

    /// Events an extension recorded while the app was not running.
    ///
    /// An extension cannot call into Flutter — it is a different process with no
    /// engine. It appends here instead, and the app drains the queue the next
    /// time it comes to the front. Without this, every intercept that happened
    /// while the app was closed would be lost, which is most of them.
    public static func enqueueEvent(_ name: String, detail: String = "") {
        guard let defaults else { return }
        var queue = defaults.array(forKey: Key.pendingEvents) as? [[String: Any]] ?? []
        queue.append([
            "name": name,
            "detail": detail,
            "at": Date().timeIntervalSince1970,
        ])
        // Bounded: a queue that grows without limit in a shared container is a
        // disk-usage bug waiting for a long offline stretch.
        if queue.count > 200 { queue.removeFirst(queue.count - 200) }
        defaults.set(queue, forKey: Key.pendingEvents)
    }

    public static func drainEvents() -> [[String: Any]] {
        guard let defaults else { return [] }
        let queue = defaults.array(forKey: Key.pendingEvents) as? [[String: Any]] ?? []
        defaults.removeObject(forKey: Key.pendingEvents)
        return queue
    }

    /// Removes everything the module holds in the shared container (§3.2).
    public static func purge() {
        guard let defaults else { return }
        for key in defaults.dictionaryRepresentation().keys {
            defaults.removeObject(forKey: key)
        }
    }
}
