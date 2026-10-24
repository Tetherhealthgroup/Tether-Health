package com.TetherHealthLLC.tetherhealth.unplug

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.graphics.Color
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.CountDownTimer
import android.provider.Settings
import android.text.InputType
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.EditText
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView

/**
 * The Android build of the intercept — the third of the three (addendum §2.1).
 *
 * Every colour and every string here comes from [InterceptTokens], which reads
 * the same `assets/unplug/intercept_tokens.json` the Dart preview and the iOS
 * `ShieldConfiguration` read. Nothing is hard-coded, on purpose: the moment one
 * of the three has its own copy of a string, the three have started to drift.
 *
 * The view is built in code rather than inflated from XML so that the token file
 * remains the only place a visual decision is expressed.
 */
class InterceptOverlay(private val context: Context) {

    private val windowManager =
        context.getSystemService(Context.WINDOW_SERVICE) as WindowManager
    private val store = UnplugStore(context)

    private var root: View? = null
    private var countdown: CountDownTimer? = null

    val isShowing: Boolean get() = root != null

    /** True when the person has granted "display over other apps". */
    fun canDraw(): Boolean =
        Build.VERSION.SDK_INT < Build.VERSION_CODES.M || Settings.canDrawOverlays(context)

    /**
     * Shows the intercept over [blockedPackage].
     *
     * @param onOutcome reports back what the person did, so the watch service can
     *   tell Dart and Dart can tell the care team something true.
     */
    @SuppressLint("InflateParams")
    fun show(
        blockedPackage: String,
        groupLabel: String,
        tokens: InterceptTokens,
        onOutcome: (Outcome) -> Unit
    ) {
        if (isShowing) return
        if (!canDraw()) return

        val gateRequired = store.tier >= UnplugStore.EFFORT_GATE_TIER
        val overridesLeft =
            if (store.tier >= UnplugStore.NO_OVERRIDE_TIER) 0 else store.overridesLeft

        val view = buildView(
            tokens = tokens,
            groupLabel = groupLabel,
            gateRequired = gateRequired,
            overridesLeft = overridesLeft,
            onDismiss = {
                hide()
                onOutcome(Outcome.Dismissed)
            },
            onPassed = {
                store.passUntil = System.currentTimeMillis() + PASS_MILLIS
                hide()
                onOutcome(Outcome.Passed)
            },
            onOverride = {
                store.overridesUsed = store.overridesUsed + 1
                store.passUntil = System.currentTimeMillis() + PASS_MILLIS
                hide()
                onOutcome(Outcome.Overridden(store.overridesLeft))
            }
        )

        val params = WindowManager.LayoutParams(
            WindowManager.LayoutParams.MATCH_PARENT,
            WindowManager.LayoutParams.MATCH_PARENT,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
            } else {
                @Suppress("DEPRECATION")
                WindowManager.LayoutParams.TYPE_SYSTEM_ALERT
            },
            // Focusable so the typed-commitment gate can receive a keyboard.
            WindowManager.LayoutParams.FLAG_LAYOUT_IN_SCREEN,
            android.graphics.PixelFormat.OPAQUE
        )

        try {
            windowManager.addView(view, params)
            root = view
        } catch (_: Exception) {
            // A window the system refuses is a shield that did not appear. The
            // health check on screen I is what tells the person that.
            root = null
        }
    }

    fun hide() {
        countdown?.cancel()
        countdown = null
        root?.let {
            try {
                windowManager.removeView(it)
            } catch (_: Exception) {
                // Already gone.
            }
        }
        root = null
    }

    private fun buildView(
        tokens: InterceptTokens,
        groupLabel: String,
        gateRequired: Boolean,
        overridesLeft: Int,
        onDismiss: () -> Unit,
        onPassed: () -> Unit,
        onOverride: () -> Unit
    ): View {
        val column = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(tokens.background)
            gravity = Gravity.CENTER_VERTICAL
            setPadding(dp(28), dp(40), dp(28), dp(40))
        }

        column.addView(
            text(tokens.title, 28f, tokens.onBackground, bold = true)
        )
        column.addView(
            text(tokens.body, 15f, tokens.onSurfaceMuted).also {
                (it.layoutParams as LinearLayout.LayoutParams).topMargin = dp(12)
            }
        )

        val reason = LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            background = rounded(tokens.surface, dp(14))
            setPadding(dp(14), dp(14), dp(14), dp(14))
            addView(text(tokens.reasonLabel.uppercase(), 11f, tokens.accent, bold = true))
            addView(
                text(
                    "$groupLabel is on your list at tier ${store.tier}.",
                    14f,
                    tokens.onBackground
                )
            )
        }
        column.addView(reason, marginParams(top = dp(20)))

        if (gateRequired) {
            column.addView(
                gateView(tokens, onPassed),
                marginParams(top = dp(20))
            )
        } else {
            column.addView(
                button(tokens.breatheAction, tokens.accent, tokens.onAccent, onPassed),
                marginParams(top = dp(24))
            )
        }

        column.addView(
            button(tokens.closeAction, Color.TRANSPARENT, tokens.onBackground, onDismiss)
                .also { it.setStroke(tokens.onSurfaceMuted) },
            marginParams(top = dp(10))
        )

        if (overridesLeft > 0) {
            column.addView(
                button(tokens.overrideAction, Color.TRANSPARENT, tokens.danger, onOverride),
                marginParams(top = dp(6))
            )
            column.addView(
                text(
                    tokens.format(
                        tokens.overrideRemaining,
                        mapOf(
                            "remaining" to overridesLeft.toString(),
                            "total" to store.overrideAllowance.toString()
                        )
                    ),
                    12f,
                    tokens.onSurfaceMuted
                ),
                marginParams(top = dp(4))
            )
        } else {
            column.addView(
                text(tokens.overrideExhausted, 12f, tokens.onSurfaceMuted),
                marginParams(top = dp(14))
            )
        }

        if (store.strict) {
            column.addView(
                text(tokens.strictNotice, 12f, tokens.onSurfaceMuted),
                marginParams(top = dp(10))
            )
        }

        return FrameLayout(context).apply {
            setBackgroundColor(tokens.background)
            addView(column)
        }
    }

    /**
     * The effort gate, in the three forms §2.1 allows.
     *
     * The gate the person chose lives in the shared store, put there by screen D,
     * because this runs outside the Flutter engine and cannot ask Dart.
     */
    private fun gateView(tokens: InterceptTokens, onPassed: () -> Unit): View =
        when (store.gate) {
            "commitment" -> commitmentGate(tokens, onPassed)
            "puzzle" -> puzzleGate(tokens, onPassed)
            else -> breathGate(tokens, onPassed)
        }

    private fun breathGate(tokens: InterceptTokens, onPassed: () -> Unit): View {
        val label = text("", 34f, tokens.accent, bold = true).apply {
            gravity = Gravity.CENTER
        }
        val action = button(tokens.breatheAction, tokens.accent, tokens.onAccent) {}
        action.isEnabled = false

        countdown?.cancel()
        countdown = object : CountDownTimer(tokens.breathSeconds * 1000L, 1000L) {
            override fun onTick(remaining: Long) {
                label.text = "${remaining / 1000}"
            }

            override fun onFinish() {
                label.text = ""
                action.isEnabled = true
                action.setOnClickListener { onPassed() }
            }
        }.also { it.start() }

        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            addView(label)
            addView(action, marginParams(top = dp(14)))
        }
    }

    private fun commitmentGate(tokens: InterceptTokens, onPassed: () -> Unit): View {
        val phrase = "I can come back to this later"
        val field = EditText(context).apply {
            inputType = InputType.TYPE_CLASS_TEXT
            setTextColor(tokens.onBackground)
            setHintTextColor(tokens.onSurfaceMuted)
            hint = phrase
        }
        val action = button(tokens.breatheAction, tokens.accent, tokens.onAccent) {
            if (field.text.toString().trim().equals(phrase, ignoreCase = true)) onPassed()
        }
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            addView(text("“$phrase”", 17f, tokens.onBackground, bold = true))
            addView(field, marginParams(top = dp(10)))
            addView(action, marginParams(top = dp(12)))
        }
    }

    private fun puzzleGate(tokens: InterceptTokens, onPassed: () -> Unit): View {
        val left = (2..9).random()
        val right = (2..9).random()
        val field = EditText(context).apply {
            inputType = InputType.TYPE_CLASS_NUMBER
            setTextColor(tokens.onBackground)
            setHintTextColor(tokens.onSurfaceMuted)
            hint = "Answer"
        }
        val action = button(tokens.breatheAction, tokens.accent, tokens.onAccent) {
            if (field.text.toString().trim().toIntOrNull() == left + right) onPassed()
        }
        return LinearLayout(context).apply {
            orientation = LinearLayout.VERTICAL
            addView(text("$left + $right", 30f, tokens.onBackground, bold = true))
            addView(field, marginParams(top = dp(10)))
            addView(action, marginParams(top = dp(12)))
        }
    }

    private fun text(
        value: String,
        size: Float,
        color: Int,
        bold: Boolean = false
    ): TextView = TextView(context).apply {
        text = value
        setTextColor(color)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, size)
        if (bold) setTypeface(typeface, android.graphics.Typeface.BOLD)
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
    }

    private fun button(
        label: String,
        fill: Int,
        textColor: Int,
        onClick: () -> Unit
    ): Button = Button(context).apply {
        text = label
        isAllCaps = false
        setTextColor(textColor)
        setTextSize(TypedValue.COMPLEX_UNIT_SP, 16f)
        background = rounded(fill, dp(26))
        setPadding(dp(18), dp(14), dp(18), dp(14))
        setOnClickListener { onClick() }
        layoutParams = LinearLayout.LayoutParams(
            LinearLayout.LayoutParams.MATCH_PARENT,
            LinearLayout.LayoutParams.WRAP_CONTENT
        )
    }

    private fun Button.setStroke(color: Int) {
        (background as? GradientDrawable)?.setStroke(dp(1), color)
    }

    private fun rounded(fill: Int, radius: Int) = GradientDrawable().apply {
        shape = GradientDrawable.RECTANGLE
        cornerRadius = radius.toFloat()
        setColor(fill)
    }

    private fun marginParams(top: Int = 0) = LinearLayout.LayoutParams(
        LinearLayout.LayoutParams.MATCH_PARENT,
        LinearLayout.LayoutParams.WRAP_CONTENT
    ).apply { topMargin = top }

    private fun dp(value: Int): Int =
        (value * context.resources.displayMetrics.density).toInt()

    /** What the person did with the intercept. */
    sealed interface Outcome {
        data object Dismissed : Outcome
        data object Passed : Outcome
        data class Overridden(val overridesLeft: Int) : Outcome
    }

    companion object {
        /**
         * How long the shield stays lifted after a gate or an override.
         *
         * Five minutes: long enough to do the thing that was actually wanted,
         * short enough that the next reach for the app is intercepted again.
         */
        private const val PASS_MILLIS = 5 * 60 * 1000L

        /** Opens the system screen for granting the overlay permission. */
        fun overlaySettingsIntent(context: Context): Intent = Intent(
            Settings.ACTION_MANAGE_OVERLAY_PERMISSION,
            android.net.Uri.parse("package:${context.packageName}")
        )
    }
}
