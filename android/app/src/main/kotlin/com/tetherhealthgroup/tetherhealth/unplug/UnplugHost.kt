package com.tetherhealthgroup.tetherhealth.unplug

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Build
import android.provider.Settings
import io.flutter.plugin.common.BinaryMessenger
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlin.coroutines.resume

/**
 * The Android half of the channel contract in addendum §2.3.
 *
 * Everything above this line is Dart. This class holds no product logic: it does
 * not know what a tier means, only that a number arrived and the shared store
 * and the watch service both need it. Tier logic leaking into native code is the
 * specific failure §2.3 warns against, and the way to notice it happening is
 * that a method here starts needing an `if`.
 */
class UnplugHost(
    private val context: Context,
    messenger: BinaryMessenger
) : UnplugHostApi, UnplugWatchService.Listener {

    private val store = UnplugStore(context)
    private val reader = UsageReader(context)
    private val flutter = UnplugFlutterApi(messenger)
    private val scope = CoroutineScope(Dispatchers.Main)

    /** Set by MainActivity while it is resumed, for the picker and Settings. */
    var activity: Activity? = null

    private var pendingPicker: ((Int) -> Unit)? = null

    init {
        UnplugHostApi.setUp(messenger, this)
        UnplugWatchService.listener = this
    }

    fun dispose() {
        UnplugWatchService.listener = null
        activity = null
    }

    override fun isSupported(): Boolean = true

    override suspend fun requestAuthorization(
        mode: PlatformAuthorizationMode
    ): PlatformAuthorizationStatus {
        store.authorizationRequested = true

        // Usage access and the overlay are special-access permissions: neither
        // can be granted by a runtime dialog, only in Settings. The honest thing
        // is to send the person there and report what is true when they return,
        // rather than to report success because an intent was fired.
        if (!reader.hasUsageAccess()) {
            openSettings(Intent(Settings.ACTION_USAGE_ACCESS_SETTINGS))
            return PlatformAuthorizationStatus.DENIED
        }
        if (!InterceptOverlay(context).canDraw()) {
            openSettings(InterceptOverlay.overlaySettingsIntent(context))
            return PlatformAuthorizationStatus.DENIED
        }

        UnplugWatchService.start(context)
        return PlatformAuthorizationStatus.APPROVED
    }

    override fun authorizationStatus(): PlatformAuthorizationStatus = when {
        !store.authorizationRequested -> PlatformAuthorizationStatus.NOT_REQUESTED
        !reader.hasUsageAccess() -> PlatformAuthorizationStatus.DENIED
        !InterceptOverlay(context).canDraw() -> PlatformAuthorizationStatus.DENIED
        else -> PlatformAuthorizationStatus.APPROVED
    }

    override suspend fun presentAppPicker(): Long {
        val host = activity ?: return store.shieldedPackages.size.toLong()
        return suspendCancellableCoroutine { continuation ->
            pendingPicker = { count -> continuation.resume(count.toLong()) }
            host.startActivityForResult(
                Intent(host, AppPickerActivity::class.java),
                AppPickerActivity.REQUEST_CODE
            )
        }
    }

    /** Called by MainActivity when the picker returns. */
    fun onPickerResult(count: Int) {
        pendingPicker?.invoke(count)
        pendingPicker = null
    }

    override fun applyShield(
        config: PlatformModuleConfig,
        selection: PlatformAppSelection
    ) {
        store.tier = config.tier.toInt()
        store.overrideAllowance = config.overrideAllowance.toInt()
        store.overridesUsed = config.overridesUsed.toInt()
        store.gate = config.gate.name.lowercase()
        store.strict = config.strict
        store.groupLabels = selection.groupLabels

        if (store.shieldedPackages.isNotEmpty() &&
            store.tier >= UnplugStore.INTERCEPT_TIER
        ) {
            UnplugWatchService.start(context)
        }
    }

    override fun liftShield(reason: String) {
        store.passUntil = System.currentTimeMillis() + LIFT_MILLIS
    }

    override fun startSession(
        durationSeconds: Long,
        scope: PlatformShieldScope,
        strict: Boolean
    ) {
        store.sessionEndsAt = System.currentTimeMillis() + durationSeconds * 1000L
        store.sessionCoversEverything =
            scope == PlatformShieldScope.EVERYTHING_EXCEPT_ALLOWLIST
        store.strict = strict
        store.passUntil = 0L
        UnplugWatchService.start(context)
    }

    override fun endSession(overrideReason: String?) {
        store.sessionEndsAt = 0L
        store.sessionCoversEverything = false
        store.strict = false
    }

    override fun setThresholds(thresholds: PlatformThresholds) {
        store.minuteThresholds = thresholds.minutes.map { it.toInt() }
        store.openThresholds = thresholds.opens.map { it.toInt() }
        store.lastReportedThreshold = 0
    }

    override suspend fun readUsage(days: Long): PlatformUsage {
        val window = reader.readDays(days.toInt().coerceAtLeast(1), store.shieldedPackages)
        return PlatformUsage(
            dailyMinutes = window.dailyMinutes.map { it.toLong() },
            daypartMinutes = window.daypartMinutes.map { it.toLong() },
            opens = window.opens.toLong(),
            // Android counts real foreground entries, so this is not an estimate.
            opensAreApproximate = false,
            perApp = window.perApp.map {
                PlatformAppUsage(
                    label = it.label,
                    minutes = it.minutes.toLong(),
                    opens = it.opens.toLong()
                )
            }
        )
    }

    override fun trackingHealth(): List<PlatformTrackingCheck> {
        val heartbeatAge = System.currentTimeMillis() - store.lastHeartbeat
        val serviceAlive = UnplugWatchService.isRunning() &&
            store.lastHeartbeat > 0 &&
            heartbeatAge < UnplugWatchService.HEARTBEAT_STALE_MS

        return listOf(
            PlatformTrackingCheck(
                name = "Screen-time authorization",
                healthy = reader.hasUsageAccess(),
                detail = "Usage access is granted to this app."
            ),
            PlatformTrackingCheck(
                name = "Usage access permission",
                healthy = reader.hasUsageAccess(),
                detail = "The permission that lets the service read what is in " +
                    "the foreground."
            ),
            PlatformTrackingCheck(
                name = "Foreground service alive",
                healthy = serviceAlive,
                detail = if (serviceAlive) {
                    "Last reported in ${heartbeatAge / 1000}s ago."
                } else {
                    "No heartbeat. Battery management has most likely stopped it."
                }
            ),
            PlatformTrackingCheck(
                name = "Overlay permission",
                healthy = InterceptOverlay(context).canDraw(),
                detail = "Drawing over other apps is what makes the intercept appear."
            )
        )
    }

    override fun purgeLocalData(olderThanDays: Long) {
        // Everything the module holds on this device lives in one store, so the
        // sweep is total rather than selective. Usage history itself belongs to
        // the platform and is not ours to delete.
        store.purge()
        UnplugWatchService.stop(context)
    }

    // --- UnplugWatchService.Listener ------------------------------------------

    override fun onShieldShown(groupLabel: String) {
        scope.launch { flutter.onShieldShown(groupLabel) }
    }

    override fun onShieldDismissed(groupLabel: String) {
        scope.launch { flutter.onShieldDismissed(groupLabel) }
    }

    override fun onOverrideUsed(groupLabel: String, overridesLeft: Int) {
        scope.launch { flutter.onOverrideUsed(groupLabel, overridesLeft.toLong()) }
    }

    override fun onThresholdCrossed(minutes: Int, opens: Int) {
        scope.launch { flutter.onThresholdCrossed(minutes.toLong(), opens.toLong()) }
    }

    private fun openSettings(intent: Intent) {
        val host = activity
        if (host != null) {
            host.startActivity(intent)
        } else {
            context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        }
    }

    companion object {
        /** How long an explicit lift keeps the shield down. */
        private const val LIFT_MILLIS = 5 * 60 * 1000L

        /** True on the API levels this implementation targets. */
        fun supportedOnThisDevice(): Boolean =
            Build.VERSION.SDK_INT >= Build.VERSION_CODES.M
    }
}
