package com.breathefree.breathefree_patient.unplug

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.os.Bundle
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.CheckBox
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView

/**
 * The Android app picker.
 *
 * On iOS this screen does not exist: `FamilyActivityPicker` is a system
 * component and the app never learns what was chosen. Android has no equivalent
 * system picker, so the module supplies one — and then holds the result the same
 * way iOS does, in [UnplugStore] on this device only, never sent to Dart and
 * never uploaded (§1).
 *
 * Only launchable apps are offered. The manifest declares a `<queries>` entry
 * for launcher activities rather than requesting QUERY_ALL_PACKAGES, which is a
 * Play policy problem and would also reveal apps the person can never be
 * looking at.
 */
class AppPickerActivity : Activity() {

    private val chosen = linkedSetOf<String>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val store = UnplugStore(this)
        chosen.addAll(store.shieldedPackages)

        val launchables = packageManager
            .queryIntentActivities(
                Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_LAUNCHER),
                0
            )
            .mapNotNull { resolved ->
                val info = resolved.activityInfo?.applicationInfo ?: return@mapNotNull null
                if (info.packageName == packageName) return@mapNotNull null
                info.packageName to packageManager.getApplicationLabel(info).toString()
            }
            .distinctBy { it.first }
            .sortedBy { it.second.lowercase() }

        val column = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#F8F5EC"))
            setPadding(dp(20), dp(28), dp(20), dp(20))
        }

        column.addView(
            TextView(this).apply {
                text = "Choose the apps to shield"
                setTextColor(Color.parseColor("#123C37"))
                textSize = 22f
                setTypeface(typeface, android.graphics.Typeface.BOLD)
            }
        )
        column.addView(
            TextView(this).apply {
                text = "This choice stays on this phone. Tether never receives it."
                setTextColor(Color.parseColor("#536F69"))
                textSize = 14f
                setPadding(0, dp(6), 0, dp(16))
            }
        )

        launchables.forEach { (packageName, label) ->
            column.addView(
                CheckBox(this).apply {
                    text = label
                    isChecked = chosen.contains(packageName)
                    setTextColor(Color.parseColor("#123C37"))
                    textSize = 16f
                    setPadding(dp(4), dp(10), dp(4), dp(10))
                    setOnCheckedChangeListener { _, checked ->
                        if (checked) chosen.add(packageName) else chosen.remove(packageName)
                    }
                }
            )
        }

        if (launchables.isEmpty()) {
            column.addView(
                TextView(this).apply {
                    text = "No launchable apps were visible to this app."
                    setTextColor(Color.parseColor("#8C3A26"))
                    textSize = 15f
                }
            )
        }

        val done = Button(this).apply {
            text = "Done"
            isAllCaps = false
            textSize = 17f
            setOnClickListener {
                store.shieldedPackages = chosen.toSet()
                setResult(RESULT_OK, Intent().putExtra(EXTRA_COUNT, chosen.size))
                finish()
            }
        }

        val scroll = ScrollView(this).apply {
            addView(column)
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        }

        setContentView(
            LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(Color.parseColor("#F8F5EC"))
                gravity = Gravity.BOTTOM
                addView(scroll)
                addView(
                    done,
                    LinearLayout.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.WRAP_CONTENT
                    ).apply { setMargins(dp(20), dp(8), dp(20), dp(20)) }
                )
            }
        )
    }

    override fun onBackPressed() {
        // Backing out is a cancel, not a silent empty selection.
        setResult(RESULT_CANCELED)
        super.onBackPressed()
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()

    private val View.dpDensity: Float get() = resources.displayMetrics.density

    companion object {
        const val EXTRA_COUNT = "chosen_count"
        const val REQUEST_CODE = 7301
    }
}
