import DeviceActivity
import Foundation
import ManagedSettings

/// Extension one of three (addendum §2.1): the schedule and threshold monitor.
///
/// This runs in its own process, with a very tight memory budget and no Flutter.
/// It cannot call Dart and it cannot ask the app anything; the App Group is the
/// only thing it shares. So it applies and lifts the shield itself, and queues
/// what happened for the app to pick up the next time it runs.
@available(iOS 16.0, *)
class UnplugMonitorExtension: DeviceActivityMonitor {

    private let store = ManagedSettingsStore(named: ManagedSettingsStore.Name("unplug"))

    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        // A new day: the override budget and the reported threshold reset, and
        // any pass left over from last night is not carried into it.
        UnplugSharedState.overridesUsed = 0
        UnplugSharedState.lastThresholdMinutes = 0
        UnplugSharedState.passUntil = nil
        UnplugSharedState.shieldEvents = 0
        UnplugSharedState.dismissEvents = 0
    }

    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        // Outside the monitored interval nothing is shielded. Leaving a shield
        // applied past the schedule is the kind of bug that gets an app deleted.
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }

    override func eventDidReachThreshold(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventDidReachThreshold(event, activity: activity)

        // The threshold is the only usage signal iOS gives this module. It says
        // a budget was crossed; it does not say by how much, and it never says
        // which app. The report shapes itself to that (§1).
        UnplugSharedState.lastThresholdMinutes += 1
        UnplugSharedState.enqueueEvent("thresholdCrossed")

        guard UnplugSharedState.tier >= 2 else { return }
        UnplugSharedState.passUntil = nil
    }

    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
    }

    override func eventWillReachThresholdWarning(
        _ event: DeviceActivityEvent.Name,
        activity: DeviceActivityName
    ) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        UnplugSharedState.enqueueEvent("thresholdWarning")
    }
}
