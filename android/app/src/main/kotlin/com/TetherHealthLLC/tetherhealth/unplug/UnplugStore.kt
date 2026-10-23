package com.TetherHealthLLC.tetherhealth.unplug

import android.content.Context

/**
 * The shared configuration the plugin, the watch service and the overlay all read.
 *
 * This is Android's equivalent of the iOS App Group container described in
 * addendum §2.1: three components in one process that must never disagree about
 * the current tier, the override count or which apps are shielded. Everything
 * that crosses between them goes through here rather than through a static
 * field, so a service restarted by the system comes back with the same state.
 *
 * The real package selection lives here and only here. It is deliberately never
 * sent to Dart: iOS cannot supply it, and carrying it on Android alone would
 * let the two platforms tell a care team different stories (§1).
 */
class UnplugStore(context: Context) {

    private val prefs =
        context.applicationContext.getSharedPreferences(NAME, Context.MODE_PRIVATE)

    var tier: Int
        get() = prefs.getInt(KEY_TIER, 0)
        set(value) = prefs.edit().putInt(KEY_TIER, value).apply()

    var overrideAllowance: Int
        get() = prefs.getInt(KEY_ALLOWANCE, 3)
        set(value) = prefs.edit().putInt(KEY_ALLOWANCE, value).apply()

    var overridesUsed: Int
        get() = prefs.getInt(KEY_USED, 0)
        set(value) = prefs.edit().putInt(KEY_USED, value).apply()

    val overridesLeft: Int
        get() = (overrideAllowance - overridesUsed).coerceAtLeast(0)

    /** One of the [PlatformEffortGate] names, lower-cased. */
    var gate: String
        get() = prefs.getString(KEY_GATE, "none") ?: "none"
        set(value) = prefs.edit().putString(KEY_GATE, value).apply()

    var strict: Boolean
        get() = prefs.getBoolean(KEY_STRICT, false)
        set(value) = prefs.edit().putBoolean(KEY_STRICT, value).apply()

    /** The packages the person actually chose. Never leaves this device. */
    var shieldedPackages: Set<String>
        get() = prefs.getStringSet(KEY_PACKAGES, emptySet()) ?: emptySet()
        set(value) = prefs.edit().putStringSet(KEY_PACKAGES, value).apply()

    /** The labels the person gave their groups, for the overlay to show back. */
    var groupLabels: List<String>
        get() = prefs.getString(KEY_LABELS, "")
            ?.split(SEPARATOR)
            ?.filter { it.isNotBlank() }
            ?: emptyList()
        set(value) =
            prefs.edit().putString(KEY_LABELS, value.joinToString(SEPARATOR.toString())).apply()

    /** Epoch millis a focus session ends, or 0 when none is running. */
    var sessionEndsAt: Long
        get() = prefs.getLong(KEY_SESSION_ENDS, 0L)
        set(value) = prefs.edit().putLong(KEY_SESSION_ENDS, value).apply()

    /** True when the running session covers everything but the allowlist. */
    var sessionCoversEverything: Boolean
        get() = prefs.getBoolean(KEY_SESSION_SCOPE, false)
        set(value) = prefs.edit().putBoolean(KEY_SESSION_SCOPE, value).apply()

    /** Epoch millis until which the shield stays lifted after a gate or override. */
    var passUntil: Long
        get() = prefs.getLong(KEY_PASS_UNTIL, 0L)
        set(value) = prefs.edit().putLong(KEY_PASS_UNTIL, value).apply()

    var minuteThresholds: List<Int>
        get() = readInts(KEY_MINUTES)
        set(value) = writeInts(KEY_MINUTES, value)

    var openThresholds: List<Int>
        get() = readInts(KEY_OPENS)
        set(value) = writeInts(KEY_OPENS, value)

    /** Epoch millis the watch service last completed a poll. */
    var lastHeartbeat: Long
        get() = prefs.getLong(KEY_HEARTBEAT, 0L)
        set(value) = prefs.edit().putLong(KEY_HEARTBEAT, value).apply()

    /** Whether the person has been through the authorization flow at all. */
    var authorizationRequested: Boolean
        get() = prefs.getBoolean(KEY_AUTH_REQUESTED, false)
        set(value) = prefs.edit().putBoolean(KEY_AUTH_REQUESTED, value).apply()

    /** The highest minute threshold already reported in the current window. */
    var lastReportedThreshold: Int
        get() = prefs.getInt(KEY_LAST_THRESHOLD, 0)
        set(value) = prefs.edit().putInt(KEY_LAST_THRESHOLD, value).apply()

    fun sessionActive(now: Long): Boolean = sessionEndsAt > now

    fun shieldLifted(now: Long): Boolean = passUntil > now

    /**
     * Wipes everything the module holds on this device.
     *
     * The retention sweep in §3.2 calls this; so does account deletion. It is
     * deliberately total rather than selective — a partial wipe is the kind of
     * thing that looks compliant and is not.
     */
    fun purge() {
        prefs.edit().clear().apply()
    }

    private fun readInts(key: String): List<Int> =
        prefs.getString(key, "")
            ?.split(',')
            ?.mapNotNull { it.trim().toIntOrNull() }
            ?: emptyList()

    private fun writeInts(key: String, values: List<Int>) {
        prefs.edit().putString(key, values.joinToString(",")).apply()
    }

    companion object {
        /** Unit separator: a label may legitimately contain a comma. */
        private const val SEPARATOR = '\u001F'

        private const val NAME = "unplug_shared_state"
        private const val KEY_TIER = "tier"
        private const val KEY_ALLOWANCE = "override_allowance"
        private const val KEY_USED = "overrides_used"
        private const val KEY_GATE = "gate"
        private const val KEY_STRICT = "strict"
        private const val KEY_PACKAGES = "shielded_packages"
        private const val KEY_LABELS = "group_labels"
        private const val KEY_SESSION_ENDS = "session_ends_at"
        private const val KEY_SESSION_SCOPE = "session_covers_everything"
        private const val KEY_PASS_UNTIL = "pass_until"
        private const val KEY_MINUTES = "minute_thresholds"
        private const val KEY_OPENS = "open_thresholds"
        private const val KEY_HEARTBEAT = "last_heartbeat"
        private const val KEY_AUTH_REQUESTED = "authorization_requested"
        private const val KEY_LAST_THRESHOLD = "last_reported_threshold"

        /** The tier at and above which the intercept offers an effort gate. */
        const val EFFORT_GATE_TIER = 3

        /** The tier at and above which the intercept appears at all. */
        const val INTERCEPT_TIER = 2

        /** The tier at which overrides stop being offered. */
        const val NO_OVERRIDE_TIER = 5
    }
}
