import Foundation
import ManagedSettings

/// Extension three of three (addendum §2.1): what the intercept's buttons do.
///
/// The execution window here is short and there is no Flutter, which is what
/// rules out anything sensor-driven. A camera-based pushup counter is not
/// realistic on iOS; a breath, a typed commitment and a short puzzle are, and
/// the two that need input are handled by the app rather than in here.
@available(iOS 16.0, *)
class UnplugShieldActionExtension: ShieldActionDelegate {

    override func handle(
        action: ShieldAction,
        for application: ApplicationToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(resolve(action))
    }

    override func handle(
        action: ShieldAction,
        for webDomain: WebDomainToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(resolve(action))
    }

    override func handle(
        action: ShieldAction,
        for category: ActivityCategoryToken,
        completionHandler: @escaping (ShieldActionResponse) -> Void
    ) {
        completionHandler(resolve(action))
    }

    private func resolve(_ action: ShieldAction) -> ShieldActionResponse {
        switch action {
        case .primaryButtonPressed:
            let tier = UnplugSharedState.tier
            if tier >= 3 && UnplugSharedState.gate != "none" {
                // The gate needs input this process has no time or UI to take.
                // Sending the person to the app is the honest handling: the
                // shield stays up until the gate is actually cleared there.
                UnplugSharedState.enqueueEvent("gateRequested", detail: UnplugSharedState.gate)
                return .defer
            }
            UnplugSharedState.dismissEvents += 1
            UnplugSharedState.enqueueEvent(
                "shieldDismissed",
                detail: UnplugSharedState.groupLabels.first ?? ""
            )
            return .close

        case .secondaryButtonPressed:
            guard UnplugSharedState.tier < 5, UnplugSharedState.overridesLeft > 0 else {
                return .defer
            }
            UnplugSharedState.overridesUsed += 1
            UnplugSharedState.grantPass()
            UnplugSharedState.enqueueEvent(
                "overrideUsed",
                detail: UnplugSharedState.groupLabels.first ?? ""
            )
            // The shield is lifted by the app clearing the store; deferring here
            // keeps the decision in one place rather than two.
            return .defer

        @unknown default:
            return .close
        }
    }
}
