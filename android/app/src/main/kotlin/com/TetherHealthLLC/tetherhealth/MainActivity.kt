package com.TetherHealthLLC.tetherhealth

import android.content.Intent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import com.TetherHealthLLC.tetherhealth.store.TetherStore
import com.TetherHealthLLC.tetherhealth.unplug.AppPickerActivity
import com.TetherHealthLLC.tetherhealth.unplug.UnplugHost

/**
 * Hosts the Flutter engine and the two channels: the Unplug module's screen-time
 * boundary (addendum §2.3) and the shell's key/value store.
 *
 * Both hosts are created with the engine rather than lazily. For Unplug that is
 * so the very first `isSupported()` call from Dart has something to answer it;
 * without it the module would fall back to its simulation on a build that does
 * have a screen-time layer, and quietly show made-up numbers. For the store the
 * reason is sharper still: Dart reads the saved session before the first frame,
 * and a store registered a moment later reads as a store that is not there,
 * which the shell would take as an instruction to start empty.
 */
class MainActivity : FlutterActivity() {

    private var unplug: UnplugHost? = null
    private var store: TetherStore? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        unplug = UnplugHost(applicationContext, messenger).also { it.activity = this }
        store = TetherStore(applicationContext, messenger)
    }

    override fun onDestroy() {
        unplug?.dispose()
        unplug = null
        store?.dispose()
        store = null
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
