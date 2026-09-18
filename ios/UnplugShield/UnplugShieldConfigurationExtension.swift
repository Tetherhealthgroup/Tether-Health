import ManagedSettings
import ManagedSettingsUI
import UIKit

/// Extension two of three (addendum §2.1): the intercept the person actually sees.
///
/// This is screen C, rebuilt natively because it has to be — the Flutter
/// intercept cannot be reused here, and this process cannot run an engine. Every
/// colour and string comes from `assets/unplug/intercept_tokens.json`, the same
/// file the Dart preview and the Android overlay read, because three separately
/// maintained copies of this screen drift apart within two sprints.
@available(iOS 16.0, *)
class UnplugShieldConfigurationExtension: ShieldConfigurationDataSource {

    override func configuration(shielding application: Application) -> ShieldConfiguration {
        UnplugSharedState.shieldEvents += 1
        UnplugSharedState.enqueueEvent(
            "shieldShown",
            detail: UnplugSharedState.groupLabels.first ?? ""
        )
        return build()
    }

    override func configuration(
        shielding application: Application,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        configuration(shielding: application)
    }

    override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
        UnplugSharedState.shieldEvents += 1
        return build()
    }

    override func configuration(
        shielding webDomain: WebDomain,
        in category: ActivityCategory
    ) -> ShieldConfiguration {
        configuration(shielding: webDomain)
    }

    private func build() -> ShieldConfiguration {
        // No fallback palette. If the shared token file cannot be read, the
        // shield says so instead of inventing colours — a silently different
        // intercept is the exact drift the shared file prevents.
        guard let tokens = InterceptTokens.load() else {
            return ShieldConfiguration(
                title: ShieldConfiguration.Label(
                    text: "Paused",
                    color: .white
                ),
                subtitle: ShieldConfiguration.Label(
                    text: "The shared intercept token file could not be read on "
                        + "this device. Open BreatheFree to see why.",
                    color: .lightGray
                ),
                primaryButtonLabel: ShieldConfiguration.Label(
                    text: "Close",
                    color: .white
                )
            )
        }

        let tier = UnplugSharedState.tier
        let left = tier >= 5 ? 0 : UnplugSharedState.overridesLeft
        let group = UnplugSharedState.groupLabels.first ?? "This app"

        let subtitle = tokens.text("body")
            + "\n\n"
            + tokens.text("reasonLabel")
            + ": \(group) is on your list at tier \(tier)."
            + "\n"
            + (left > 0
                ? tokens.text(
                    "overrideRemaining",
                    [
                        "remaining": String(left),
                        "total": String(UnplugSharedState.overrideAllowance),
                    ]
                )
                : tokens.text("overrideExhausted"))

        return ShieldConfiguration(
            backgroundBlurStyle: .systemUltraThinMaterialDark,
            backgroundColor: tokens.uiColor("background"),
            icon: nil,
            title: ShieldConfiguration.Label(
                text: tokens.text("title"),
                color: tokens.uiColor("onBackground")
            ),
            subtitle: ShieldConfiguration.Label(
                text: subtitle,
                color: tokens.uiColor("onSurfaceMuted")
            ),
            primaryButtonLabel: ShieldConfiguration.Label(
                text: tier >= 3 ? tokens.text("breatheAction") : tokens.text("closeAction"),
                color: tokens.uiColor("onAccent")
            ),
            primaryButtonBackgroundColor: tokens.uiColor("accent"),
            secondaryButtonLabel: left > 0
                ? ShieldConfiguration.Label(
                    text: tokens.text("overrideAction"),
                    color: tokens.uiColor("danger")
                )
                : nil
        )
    }
}
