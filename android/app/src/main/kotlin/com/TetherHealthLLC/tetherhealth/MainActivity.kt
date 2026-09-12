package com.TetherHealthLLC.tetherhealth

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.TetherHealthLLC.tetherhealth.unplug.AppPickerActivity
import com.TetherHealthLLC.tetherhealth.unplug.UnplugHost

/**
 * Hosts the Flutter engine and the Unplug channel (addendum §2.3).
 *
 * The host is created with the engine rather than lazily, so the very first
 * `isSupported()` call from Dart has something to answer it. Without that, the
 * module would fall back to its simulation on a build that does have a
 * screen-time layer, and quietly show made-up numbers.
 */
class MainActivity : FlutterActivity() {

    private var unplug: UnplugHost? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        unplug = UnplugHost(
            applicationContext,
            flutterEngine.dartExecutor.binaryMessenger
        ).also { it.activity = this }
    }

    override fun onDestroy() {
        unplug?.dispose()
        unplug = null
        super.onDestroy()
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == AppPickerActivity.REQUEST_CODE) {
            unplug?.onPickerResult(
                data?.getIntExtra(AppPickerActivity.EXTRA_COUNT, 0) ?: 0
            )
        }
    }
}
