package com.tetherhealthgroup.tetherhealth.unplug

import android.content.Context
import android.graphics.Color
import io.flutter.FlutterInjector
import org.json.JSONObject

/**
 * The Kotlin reader for the shared intercept tokens.
 *
 * Addendum §2.1 warns that the intercept, built three times, drifts apart within
 * two sprints unless the colours and copy live in one file all three read. That
 * file is `assets/unplug/intercept_tokens.json`, shipped in the Flutter asset
 * bundle; this is the Android reader for it, and the overlay draws nothing that
 * is not in here.
 *
 * Parsing is strict, exactly as the Dart reader is. A malformed token file is a
 * file the other two implementations will also fail on, and quietly falling back
 * to a hard-coded colour would hide precisely the drift this file prevents.
 */
data class InterceptTokens(
    val version: String,
    val background: Int,
    val surface: Int,
    val onBackground: Int,
    val onSurfaceMuted: Int,
    val accent: Int,
    val onAccent: Int,
    val danger: Int,
    val title: String,
    val body: String,
    val reasonLabel: String,
    val breatheAction: String,
    val closeAction: String,
    val overrideAction: String,
    val overrideRemaining: String,
    val overrideExhausted: String,
    val strictNotice: String,
    val breathSeconds: Int,
    val latencyMinMs: Int,
    val latencyMaxMs: Int
) {

    /** Substitutes `{name}` placeholders, matching the Dart reader's contract. */
    fun format(template: String, values: Map<String, String>): String =
        values.entries.fold(template) { text, entry ->
            text.replace("{${entry.key}}", entry.value)
        }

    companion object {
        const val ASSET_PATH = "assets/unplug/intercept_tokens.json"

        @Volatile
        private var cached: InterceptTokens? = null

        /**
         * Reads and caches the token file.
         *
         * @throws IllegalStateException when the file is missing or malformed.
         */
        fun load(context: Context): InterceptTokens {
            cached?.let { return it }
            val key = FlutterInjector.instance()
                .flutterLoader()
                .getLookupKeyForAsset(ASSET_PATH)
            val raw = try {
                context.assets.open(key).bufferedReader().use { it.readText() }
            } catch (error: Exception) {
                throw IllegalStateException(
                    "The shared intercept token file could not be read at $key. " +
                        "The Dart and SwiftUI intercepts read the same file.",
                    error
                )
            }
            return parse(raw).also { cached = it }
        }

        fun parse(raw: String): InterceptTokens {
            val root = JSONObject(raw)
            val colors = root.getJSONObject("colors")
            val copy = root.getJSONObject("copy")
            val timing = root.getJSONObject("timing")
            return InterceptTokens(
                version = root.getString("version"),
                background = color(colors, "background"),
                surface = color(colors, "surface"),
                onBackground = color(colors, "onBackground"),
                onSurfaceMuted = color(colors, "onSurfaceMuted"),
                accent = color(colors, "accent"),
                onAccent = color(colors, "onAccent"),
                danger = color(colors, "danger"),
                title = copy.getString("title"),
                body = copy.getString("body"),
                reasonLabel = copy.getString("reasonLabel"),
                breatheAction = copy.getString("breatheAction"),
                closeAction = copy.getString("closeAction"),
                overrideAction = copy.getString("overrideAction"),
                overrideRemaining = copy.getString("overrideRemaining"),
                overrideExhausted = copy.getString("overrideExhausted"),
                strictNotice = copy.getString("strictNotice"),
                breathSeconds = timing.getInt("breathSeconds"),
                latencyMinMs = timing.getInt("androidOverlayLatencyMsMin"),
                latencyMaxMs = timing.getInt("androidOverlayLatencyMsMax")
            )
        }

        /** Parses `#RRGGBB`, the form the Dart and Swift readers also accept. */
        private fun color(source: JSONObject, name: String): Int {
            val value = source.getString(name)
            require(value.length == 7 && value.startsWith("#")) {
                "Intercept colour \"$name\" is not #RRGGBB."
            }
            return Color.parseColor(value)
        }
    }
}
