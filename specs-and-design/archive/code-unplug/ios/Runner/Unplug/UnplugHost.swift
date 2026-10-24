import DeviceActivity
import FamilyControls
import Flutter
import ManagedSettings
import SwiftUI
import UIKit

/// The iOS half of the channel contract in addendum §2.3.
///
/// What this can and cannot do is set by §1, not by effort. `FamilyControls`
/// hands back opaque, device-local `ApplicationToken`s: they can be shielded,
/// they can be drawn with Apple's own label view, and that is the entire list.
/// They cannot be named, they cannot be transmitted, and the
/// `DeviceActivityReport` extension that computes usage detail has no network
/// access by design.
///
/// So `readUsage` here returns a shape, not a measurement, and says so through
/// `opensAreApproximate`. The only numbers iOS will give this module are
/// threshold crossings and shield events, both of which arrive through the
/// extensions and the App Group rather than through a query.
@available(iOS 16.0, *)
final class UnplugHost: NSObject, UnplugHostApi {

    /// Identifies the monitoring schedule this module owns.
    static let activityName = DeviceActivityName("unplug.daily")

    /// Identifies the usage threshold inside that schedule.
    static let eventName = DeviceActivityEvent.Name("unplug.threshold")

    /// The store the shield is written to. Extensions address the same store by
    /// name, which is how a shield applied here is visible over there.
    private let managedSettings = ManagedSettingsStore(
        named: ManagedSettingsStore.Name("unplug")
    )

    private let center = DeviceActivityCenter()
    private let flutter: UnplugFlutterApi
    private weak var controller: UIViewController?

    /// The current selection. Device-local: it is never encoded or sent.
    private var selection = FamilyActivitySelection()

    init(binaryMessenger: FlutterBinaryMessenger, controller: UIViewController?) {
        self.flutter = UnplugFlutterApi(binaryMessenger: binaryMessenger)
        self.controller = controller
        super.init()
        UnplugHostApiSetup.setUp(binaryMessenger: binaryMessenger, api: self)
    }

    /// Forwards anything the extensions recorded while the app was closed.
    ///
    /// An extension cannot reach Flutter — different process, no engine — so it
    /// queues into the App Group and the app drains it on the way back in.
    func drainPendingEvents() {
        let queued = UnplugSharedState.drainEvents()
        guard !queued.isEmpty else { return }
        Task { @MainActor in
            for event in queued {
                guard let name = event["name"] as? String else { continue }
                let detail = event["detail"] as? String ?? ""
                do {
                    switch name {
                    case "shieldShown":
                        try await flutter.onShieldShown(groupLabel: detail)
                    case "shieldDismissed":
                        try await flutter.onShieldDismissed(groupLabel: detail)
                    case "overrideUsed":
                        try await flutter.onOverrideUsed(
                            groupLabel: detail,
                            overridesRemaining: Int64(UnplugSharedState.overridesLeft)
                        )
                    case "thresholdCrossed":
                        try await flutter.onThresholdCrossed(
                            minutesUsed: Int64(UnplugSharedState.lastThresholdMinutes),
                            opens: Int64(UnplugSharedState.shieldEvents)
                        )
                    case "trackingStopped":
                        try await flutter.onTrackingStopped(checkName: detail, detail: "")
                    default:
                        continue
                    }
                } catch {
                    // The engine went away mid-drain. The events are already
                    // out of the queue; losing a count is better than looping.
                    return
                }
            }
        }
    }

    // MARK: - UnplugHostApi

    func isSupported() throws -> Bool { true }

    func requestAuthorization(
        mode: PlatformAuthorizationMode
    ) async throws -> PlatformAuthorizationStatus {
        UnplugSharedState.authorizationRequested = true
        do {
            // `.child` is the path that needs an iCloud Family and the
            // guardian's Screen Time passcode entered on this device (§3.1).
            try await AuthorizationCenter.shared.requestAuthorization(
                for: mode == .child ? .child : .individual
            )
            return .approved
        } catch {
            // Apple does not distinguish "declined" from "impossible here", so
            // the child path with no family is reported as the dead end it is
            // rather than as a refusal the person could reverse.
            return mode == .child ? .blockedNoFamilySharing : .denied
        }
    }

    func authorizationStatus() throws -> PlatformAuthorizationStatus {
        guard UnplugSharedState.isConfigured else { return .unavailable }
        guard UnplugSharedState.authorizationRequested else { return .notRequested }
        switch AuthorizationCenter.shared.authorizationStatus {
        case .approved: return .approved
        case .denied: return .denied
        case .notDetermined: return .notRequested
        @unknown default: return .unavailable
        }
    }

    func presentAppPicker() async throws -> Int64 {
        guard let controller else {
            return Int64(selection.applicationTokens.count)
        }
        // FamilyActivityPicker is a system component. The app hosts it and is
        // told how many things were chosen — never which.
        return await withCheckedContinuation { continuation in
            var resumed = false
            let picker = UIHostingController(
                rootView: FamilyPickerView(selection: selection) { [weak self] chosen in
                    guard !resumed else { return }
                    resumed = true
                    self?.selection = chosen
                    controller.dismiss(animated: true)
                    let count = chosen.applicationTokens.count +
                        chosen.categoryTokens.count +
                        chosen.webDomainTokens.count
                    UnplugSharedState.totalApps = count
                    continuation.resume(returning: Int64(count))
                }
            )
            controller.present(picker, animated: true)
        }
    }

    func applyShield(
        config: PlatformModuleConfig,
        selection incoming: PlatformAppSelection
    ) throws {
        UnplugSharedState.tier = Int(config.tier)
        UnplugSharedState.overrideAllowance = Int(config.overrideAllowance)
        UnplugSharedState.overridesUsed = Int(config.overridesUsed)
        UnplugSharedState.gate = gateName(config.gate)
        UnplugSharedState.strict = config.strict
        UnplugSharedState.groupLabels = incoming.groupLabels
        UnplugSharedState.totalApps = Int(incoming.totalApps)

        // Tier 0 and 1 observe and nudge; the shield itself starts at tier 2.
        guard config.tier >= 2 else {
            clearShield()
            return
        }
        managedSettings.shield.applications =
            selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        managedSettings.shield.applicationCategories =
            selection.categoryTokens.isEmpty
                ? nil
                : .specific(selection.categoryTokens)
    }

    func liftShield(reason: String) throws {
        UnplugSharedState.grantPass()
        clearShield()
    }

    func startSession(
        durationSeconds: Int64,
        scope: PlatformShieldScope,
        strict: Bool
    ) throws {
        UnplugSharedState.sessionEndsAt = Date()
            .addingTimeInterval(TimeInterval(durationSeconds))
        UnplugSharedState.sessionCoversEverything =
            scope == .everythingExceptAllowlist
        UnplugSharedState.strict = strict
        UnplugSharedState.passUntil = nil

        managedSettings.shield.applications =
            selection.applicationTokens.isEmpty ? nil : selection.applicationTokens
        if scope == .everythingExceptAllowlist {
            managedSettings.shield.applicationCategories = .all()
        }
    }

    func endSession(overrideReason: String?) throws {
        UnplugSharedState.sessionEndsAt = nil
        UnplugSharedState.sessionCoversEverything = false
        UnplugSharedState.strict = false
        clearShield()
    }

    func setThresholds(thresholds: PlatformThresholds) throws {
        center.stopMonitoring([Self.activityName])
        UnplugSharedState.scheduleActive = false

        guard let first = thresholds.minutes.first, first > 0 else { return }

        // One schedule covering the whole day, with an event that fires when the
        // first budget is crossed. DeviceActivityMonitor tells the app; there is
        // no way to poll for this on iOS.
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: true
        )
        let event = DeviceActivityEvent(
            applications: selection.applicationTokens,
            categories: selection.categoryTokens,
            threshold: DateComponents(minute: Int(first))
        )

        do {
            try center.startMonitoring(
                Self.activityName,
                during: schedule,
                events: [Self.eventName: event]
            )
            UnplugSharedState.scheduleActive = true
            UnplugSharedState.lastThresholdMinutes = 0
        } catch {
            UnplugSharedState.scheduleActive = false
        }
    }

    func readUsage(days: Int64) async throws -> PlatformUsage {
        // This is the iOS floor, and it is a hard floor. `DeviceActivityReport`
        // computes usage detail inside an extension that has no network access
        // and cannot return values to its host, so there is no API that hands
        // this process a number of minutes. What the module genuinely knows is
        // how often the shield fired, and it says so rather than inventing a
        // daily curve.
        return PlatformUsage(
            dailyMinutes: Array(repeating: Int64(0), count: Int(max(days, 1))),
            daypartMinutes: Array(repeating: Int64(0), count: 5),
            opens: Int64(UnplugSharedState.shieldEvents),
            opensAreApproximate: true,
            perApp: []
        )
    }

    func trackingHealth() throws -> [PlatformTrackingCheck] {
        let authorized = AuthorizationCenter.shared.authorizationStatus == .approved
        return [
            PlatformTrackingCheck(
                name: "Screen-time authorization",
                healthy: authorized,
                detail: authorized
                    ? "Screen Time access is granted to this app."
                    : "Screen Time access is not granted, so nothing is shielded."
            ),
            PlatformTrackingCheck(
                name: "Device activity schedule",
                healthy: UnplugSharedState.scheduleActive,
                detail: UnplugSharedState.scheduleActive
                    ? "The monitoring schedule is registered with its threshold."
                    : "No schedule is registered, so no threshold can fire."
            ),
            PlatformTrackingCheck(
                name: "App Group container",
                healthy: UnplugSharedState.isConfigured,
                detail: UnplugSharedState.isConfigured
                    ? "The extensions can read tier state and override counts."
                    : "The shared container is unreachable; the intercept would "
                        + "run on stale configuration."
            ),
        ]
    }

    func purgeLocalData(olderThanDays: Int64) throws {
        clearShield()
        center.stopMonitoring([Self.activityName])
        UnplugSharedState.purge()
        selection = FamilyActivitySelection()
    }

    // MARK: - Helpers

    private func clearShield() {
        managedSettings.shield.applications = nil
        managedSettings.shield.applicationCategories = nil
    }

    private func gateName(_ gate: PlatformEffortGate) -> String {
        switch gate {
        case .none: return "none"
        case .breath: return "breath"
        case .commitment: return "commitment"
        case .puzzle: return "puzzle"
        }
    }
}

/// Hosts Apple's `FamilyActivityPicker`.
///
/// The picker is the only way to choose apps on iOS, and it deliberately gives
/// the app tokens rather than identities. There is no version of this screen
/// that could show the person's app names to a clinician.
@available(iOS 16.0, *)
private struct FamilyPickerView: View {
    @State var selection: FamilyActivitySelection
    let onDone: (FamilyActivitySelection) -> Void

    var body: some View {
        NavigationView {
            FamilyActivityPicker(selection: $selection)
                .navigationTitle("Choose apps")
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { onDone(selection) }
                    }
                }
        }
    }
}
