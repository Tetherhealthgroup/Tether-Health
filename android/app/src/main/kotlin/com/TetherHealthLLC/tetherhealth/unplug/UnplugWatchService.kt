package com.TetherHealthLLC.tetherhealth.unplug

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Context
import android.content.Intent
import android.content.pm.ServiceInfo
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper

/**
 * The foreground service that watches for a shielded app coming to the front.
 *
 * Addendum §2.2 offered two ways to do this and this is the one it recommends:
 * poll `UsageStatsManager` and draw an overlay, rather than run an
 * `AccessibilityService`. The cost is a shield that appears within about a
 * second instead of instantly. The benefit is an app that Google does not
 * remove — and a removed app is a dead programme.
 *
 * The service writes a heartbeat on every poll. Screen I reads it, because the
 * single most common support ticket for a blocker is "it just stopped working",
 * and on Xiaomi, Samsung, Oppo and OnePlus it will have: each of them kills a
 * foreground service in its own way. The module cannot prevent that. What it can
 * do is notice, and say so.
 */
class UnplugWatchService : Service() {

    /** Reports intercept outcomes to whoever is holding the Flutter engine. */
    interface Listener {
        fun onShieldShown(groupLabel: String)
        fun onShieldDismissed(groupLabel: String)
        fun onOverrideUsed(groupLabel: String, overridesLeft: Int)
        fun onThresholdCrossed(minutes: Int, opens: Int)
    }

    private val handler = Handler(Looper.getMainLooper())
    private lateinit var store: UnplugStore
    private lateinit var reader: UsageReader
    private lateinit var overlay: InterceptOverlay
    private var tokens: InterceptTokens? = null
    private var lastForeground: String? = null

    private val poll = object : Runnable {
        override fun run() {
            try {
                tick()
            } catch (_: Exception) {
                // A failed poll must not kill the service; the heartbeat going
                // stale is what surfaces a persistent problem.
            }
            handler.postDelayed(this, POLL_INTERVAL_MS)
        }
    }

    override fun onCreate() {
        super.onCreate()
        store = UnplugStore(this)
        reader = UsageReader(this)
        overlay = InterceptOverlay(this)
        tokens = try {
            InterceptTokens.load(this)
        } catch (_: Exception) {
            // The overlay cannot be drawn without the shared token file. It is
            // not substituted for — screen C reports the same failure.
            null
        }
        // From API 34 the declared foreground-service type must be passed here
        // as well as in the manifest, or the system throws on start.
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.UPSIDE_DOWN_CAKE) {
            startForeground(
                NOTIFICATION_ID,
                buildNotification(),
                ServiceInfo.FOREGROUND_SERVICE_TYPE_SPECIAL_USE
            )
        } else {
            startForeground(NOTIFICATION_ID, buildNotification())
        }
        running = true
        handler.post(poll)
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int = START_STICKY

    override fun onDestroy() {
        handler.removeCallbacks(poll)
        overlay.hide()
        super.onDestroy()
        running = false
    }

    override fun onBind(intent: Intent?): IBinder? = null

    private fun tick() {
        val now = System.currentTimeMillis()
        store.lastHeartbeat = now

        val shielded = store.shieldedPackages
        val sessionActive = store.sessionActive(now)
        if (shielded.isEmpty() && !sessionActive) return
        if (store.tier < UnplugStore.INTERCEPT_TIER && !sessionActive) return

        reportThresholds(shielded, now)

        val foreground = reader.foregroundPackage(now) ?: return
        if (foreground == packageName) {
            lastForeground = foreground
            return
        }

        val inScope = if (sessionActive && store.sessionCoversEverything) {
            foreground != packageName
        } else {
            shielded.contains(foreground)
        }

        if (!inScope) {
            lastForeground = foreground
            if (overlay.isShowing) overlay.hide()
            return
        }

        if (store.shieldLifted(now)) return
        if (overlay.isShowing) return

        val label = store.groupLabels.firstOrNull() ?: "This app"
        val loaded = tokens ?: return
        overlay.show(foreground, label, loaded) { outcome ->
            when (outcome) {
                is InterceptOverlay.Outcome.Dismissed ->
                    listener?.onShieldDismissed(label)

                is InterceptOverlay.Outcome.Passed -> Unit
                is InterceptOverlay.Outcome.Overridden ->
                    listener?.onOverrideUsed(label, outcome.overridesLeft)
            }
        }
        listener?.onShieldShown(label)
        lastForeground = foreground
    }

    /**
     * Fires the threshold callback once per budget crossed, not once per poll.
     */
    private fun reportThresholds(shielded: Set<String>, now: Long) {
        val budgets = store.minuteThresholds
        if (budgets.isEmpty()) return
        val minutes = reader.minutesToday(shielded, now)
        val crossed = budgets.filter { it in 1..minutes }.maxOrNull() ?: return
        if (crossed <= store.lastReportedThreshold) return
        store.lastReportedThreshold = crossed
        listener?.onThresholdCrossed(minutes, reader.opensToday(shielded, now))
    }

    private fun buildNotification(): Notification {
        val manager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(
                    CHANNEL_ID,
                    "Screen-time protection",
                    NotificationManager.IMPORTANCE_LOW
                ).apply {
                    description =
                        "Shown while Unplug is watching for the apps you chose."
                    setShowBadge(false)
                }
            )
        }

        val open = PendingIntent.getActivity(
            this,
            0,
            packageManager.getLaunchIntentForPackage(packageName),
            PendingIntent.FLAG_IMMUTABLE
        )

        val builder = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            Notification.Builder(this, CHANNEL_ID)
        } else {
            @Suppress("DEPRECATION")
            Notification.Builder(this)
        }

        return builder
            .setContentTitle("Unplug is on")
            .setContentText("Watching the apps you chose. Nothing is uploaded.")
            .setSmallIcon(android.R.drawable.ic_lock_idle_lock)
            .setOngoing(true)
            .setContentIntent(open)
            .build()
    }

    companion object {
        /**
         * One second, the middle of the 0.5–1.5s the token file records as the
         * cost of polling rather than using an AccessibilityService.
         */
        private const val POLL_INTERVAL_MS = 1_000L

        private const val CHANNEL_ID = "unplug_watch"
        private const val NOTIFICATION_ID = 4201

        /**
         * How stale a heartbeat may be before screen I calls tracking stopped.
         *
         * Five minutes, matching the wording of the health check itself.
         */
        const val HEARTBEAT_STALE_MS = 5 * 60 * 1000L

        @Volatile
        var listener: Listener? = null

        @Volatile
        private var running = false

        fun isRunning(): Boolean = running

        fun start(context: Context) {
            val intent = Intent(context, UnplugWatchService::class.java)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                context.startForegroundService(intent)
            } else {
                context.startService(intent)
            }
            running = true
        }

        fun stop(context: Context) {
            context.stopService(Intent(context, UnplugWatchService::class.java))
            running = false
        }
    }
}
