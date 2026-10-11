package com.TetherHealthLLC.tetherhealth.unplug

import android.app.AppOpsManager
import android.app.usage.UsageEvents
import android.app.usage.UsageStatsManager
import android.content.Context
import android.content.pm.PackageManager
import android.os.Build
import android.os.Process
import java.util.Calendar
import java.util.concurrent.TimeUnit

/**
 * Reads what Android will actually tell the module (addendum §1).
 *
 * Unlike iOS, this yields real package names and real durations. The module
 * still shapes the result to the iOS floor — an aggregate, opens and a
 * time-of-day distribution — and offers the per-app split as clearly-labelled
 * extra detail, so a care team reading two patients' reports is never quietly
 * comparing two different things.
 *
 * Durations are reconstructed from the event stream rather than taken from
 * `queryUsageStats`, whose buckets are coarse and, on some OEM builds, wrong.
 */
class UsageReader(private val context: Context) {

    private val usageStats: UsageStatsManager? =
        context.getSystemService(Context.USAGE_STATS_SERVICE) as? UsageStatsManager

    /** The five dayparts the report is bucketed into, matching screen E. */
    private val daypartBounds = listOf(0, 6, 12, 18, 22, 24)

    data class AppTotal(val packageName: String, val label: String, val minutes: Int, val opens: Int)

    data class Window(
        val dailyMinutes: List<Int>,
        val daypartMinutes: List<Int>,
        val opens: Int,
        val perApp: List<AppTotal>
    )

    /**
     * True when the person has granted usage access.
     *
     * This is a special-access permission: it cannot be requested with a runtime
     * dialog, only by sending the person to Settings. It is also revocable
     * without telling the app, which is why screen I exists.
     */
    fun hasUsageAccess(): Boolean {
        val appOps = context.getSystemService(Context.APP_OPS_SERVICE) as? AppOpsManager
            ?: return false
        val mode = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            appOps.unsafeCheckOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        } else {
            @Suppress("DEPRECATION")
            appOps.checkOpNoThrow(
                AppOpsManager.OPSTR_GET_USAGE_STATS,
                Process.myUid(),
                context.packageName
            )
        }
        return mode == AppOpsManager.MODE_ALLOWED
    }

    /**
     * The package currently in the foreground, or null when it cannot be told.
     *
     * Polled by [UnplugWatchService] roughly once a second. This is the
     * deliberate cost of not using an AccessibilityService: a shield that
     * appears within about a second rather than instantly, in exchange for an
     * app that does not get pulled from the Play Store (§2.2).
     */
    fun foregroundPackage(now: Long = System.currentTimeMillis()): String? {
        val manager = usageStats ?: return null
        val events = manager.queryEvents(now - TimeUnit.SECONDS.toMillis(30), now)
        val event = UsageEvents.Event()
        var latest: String? = null
        var latestAt = 0L
        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (event.eventType == UsageEvents.Event.ACTIVITY_RESUMED &&
                event.timeStamp >= latestAt
            ) {
                latest = event.packageName
                latestAt = event.timeStamp
            }
        }
        return latest
    }

    /** Minutes spent in [packages] since local midnight. */
    fun minutesToday(packages: Set<String>, now: Long = System.currentTimeMillis()): Int {
        if (packages.isEmpty()) return 0
        val window = read(startOfDay(now), now, packages)
        return window.dailyMinutes.sum()
    }

    /** Foreground entries into [packages] since local midnight. */
    fun opensToday(packages: Set<String>, now: Long = System.currentTimeMillis()): Int {
        if (packages.isEmpty()) return 0
        return read(startOfDay(now), now, packages).opens
    }

    /**
     * Reads the last [days] days, oldest day first.
     *
     * When [packages] is empty every app is counted, which is what the baseline
     * report wants before a selection exists.
     */
    fun readDays(days: Int, packages: Set<String>): Window {
        val now = System.currentTimeMillis()
        val start = startOfDay(now) - TimeUnit.DAYS.toMillis((days - 1).toLong())
        return read(start, now, packages, days)
    }

    private fun read(
        from: Long,
        to: Long,
        packages: Set<String>,
        dayCount: Int = 1
    ): Window {
        val manager = usageStats
            ?: return Window(List(dayCount) { 0 }, List(5) { 0 }, 0, emptyList())

        val events = manager.queryEvents(from, to)
        val event = UsageEvents.Event()

        val resumedAt = HashMap<String, Long>()
        val dailyMillis = LongArray(dayCount)
        val daypartMillis = LongArray(5)
        val perAppMillis = HashMap<String, Long>()
        val perAppOpens = HashMap<String, Int>()
        var opens = 0

        fun counted(packageName: String) =
            packages.isEmpty() || packages.contains(packageName)

        fun close(packageName: String, endedAt: Long) {
            val startedAt = resumedAt.remove(packageName) ?: return
            if (endedAt <= startedAt) return
            val duration = endedAt - startedAt
            perAppMillis[packageName] = (perAppMillis[packageName] ?: 0L) + duration
            val dayIndex = ((startOfDay(startedAt) - startOfDay(from)) /
                TimeUnit.DAYS.toMillis(1)).toInt()
            if (dayIndex in 0 until dayCount) dailyMillis[dayIndex] += duration
            daypartMillis[daypartOf(startedAt)] += duration
        }

        while (events.hasNextEvent()) {
            events.getNextEvent(event)
            if (!counted(event.packageName)) continue
            when (event.eventType) {
                UsageEvents.Event.ACTIVITY_RESUMED -> {
                    resumedAt[event.packageName] = event.timeStamp
                    opens++
                    perAppOpens[event.packageName] =
                        (perAppOpens[event.packageName] ?: 0) + 1
                }

                UsageEvents.Event.ACTIVITY_PAUSED,
                UsageEvents.Event.ACTIVITY_STOPPED -> close(event.packageName, event.timeStamp)
            }
        }
        // Anything still in the foreground when the window ends counts up to now.
        resumedAt.keys.toList().forEach { close(it, to) }

        val labels = context.packageManager
        return Window(
            dailyMinutes = dailyMillis.map { TimeUnit.MILLISECONDS.toMinutes(it).toInt() },
            daypartMinutes = daypartMillis.map { TimeUnit.MILLISECONDS.toMinutes(it).toInt() },
            opens = opens,
            perApp = perAppMillis.entries
                .map { (packageName, millis) ->
                    AppTotal(
                        packageName = packageName,
                        label = labelFor(labels, packageName),
                        minutes = TimeUnit.MILLISECONDS.toMinutes(millis).toInt(),
                        opens = perAppOpens[packageName] ?: 0
                    )
                }
                .filter { it.minutes > 0 }
                .sortedByDescending { it.minutes }
        )
    }

    /**
     * A human label for a package.
     *
     * Falls back to the package name rather than to a guess. The manifest
     * declares a `<queries>` entry for launcher activities instead of
     * QUERY_ALL_PACKAGES: the broad permission is a Play policy problem, and
     * launchable apps are the only ones a person can be looking at anyway.
     */
    private fun labelFor(manager: PackageManager, packageName: String): String = try {
        manager.getApplicationLabel(manager.getApplicationInfo(packageName, 0)).toString()
    } catch (_: PackageManager.NameNotFoundException) {
        packageName
    }

    private fun daypartOf(millis: Long): Int {
        val calendar = Calendar.getInstance().apply { timeInMillis = millis }
        val hour = calendar.get(Calendar.HOUR_OF_DAY)
        for (index in 0 until daypartBounds.size - 1) {
            if (hour >= daypartBounds[index] && hour < daypartBounds[index + 1]) return index
        }
        return daypartBounds.size - 2
    }

    private fun startOfDay(millis: Long): Long = Calendar.getInstance().apply {
        timeInMillis = millis
        set(Calendar.HOUR_OF_DAY, 0)
        set(Calendar.MINUTE, 0)
        set(Calendar.SECOND, 0)
        set(Calendar.MILLISECOND, 0)
    }.timeInMillis
}
