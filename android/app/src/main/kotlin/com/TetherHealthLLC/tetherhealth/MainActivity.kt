package com.TetherHealthLLC.tetherhealth

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.provider.Settings
import com.TetherHealthLLC.tetherhealth.unplug.AppPickerActivity
import com.TetherHealthLLC.tetherhealth.unplug.UnplugHost
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    // The Unplug module's screen-time boundary (UnplugApi). Created with the
    // engine so the first `isSupported()` call from Dart has something to
    // answer it.
    private var unplug: UnplugHost? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        unplug = UnplugHost(applicationContext, messenger).also { it.activity = this }
        // Two fixed actions for the app's own screens. Neither reads any
        // argument from Dart: the intents are built here only.
        MethodChannel(messenger, PLATFORM_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openAppSettings" -> result.success(
                        start(
                            Intent(
                                Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                                Uri.fromParts("package", packageName, null),
                            ),
                        ),
                    )
                    "openEmailApp" -> result.success(
                        start(Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_APP_EMAIL)),
                    )
                    else -> result.notImplemented()
                }
            }
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
                data?.getIntExtra(AppPickerActivity.EXTRA_COUNT, 0) ?: 0,
            )
        }
    }

    /** Starts [intent] in a new task; false when no activity can handle it. */
    private fun start(intent: Intent): Boolean =
        try {
            startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
            true
        } catch (e: ActivityNotFoundException) {
            false
        }

    private companion object {
        const val PLATFORM_CHANNEL = "com.tetherhealthllc.tetherhealth/platform"
    }
}
