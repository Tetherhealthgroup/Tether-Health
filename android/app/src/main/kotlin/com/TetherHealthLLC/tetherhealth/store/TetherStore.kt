package com.TetherHealthLLC.tetherhealth.store

import android.content.Context
import io.flutter.plugin.common.BinaryMessenger

/**
 * The Android half of the shell's key/value contract.
 *
 * Backed by a `SharedPreferences` file of its own, `tether_shell_state`, and
 * deliberately not by `unplug_shared_state`. That file is the Unplug module's:
 * the plugin, the watch service and the overlay all read it because they must
 * agree about the current tier and the override count. Nothing here is theirs —
 * this is the shell's enrolments, the person's answers and their lapse history.
 * Sharing one file would mean the overlay process could read which health
 * programmes somebody is enrolled in, for no benefit, and `purge()` on either
 * side would silently take the other's data with it.
 *
 * This class holds no product logic. It does not know what a snapshot contains
 * and must not learn: everything about shape, schema version and migration is
 * Dart, where it can be tested without a device.
 */
class TetherStore(
    context: Context,
    private val messenger: BinaryMessenger
) : TetherStoreApi {

    private val prefs =
        context.applicationContext.getSharedPreferences(NAME, Context.MODE_PRIVATE)

    init {
        TetherStoreApi.setUp(messenger, this)
    }

    /** Detaches the handler so a rebuilt engine does not talk to a dead one. */
    fun dispose() {
        TetherStoreApi.setUp(messenger, null)
    }

    override fun read(key: String): String? = prefs.getString(key, null)

    /**
     * Written with `commit()` rather than `apply()`.
     *
     * `apply()` returns immediately and writes on a background thread, which is
     * the right default and the wrong one here: the call that reaches this is
     * the app being backgrounded and flushing the last edit, which is precisely
     * the moment the process is most likely to be killed before an asynchronous
     * write lands. The channel call is already off the main thread as far as
     * Dart is concerned, so the cost is paid by nobody.
     */
    override fun write(key: String, value: String) {
        prefs.edit().putString(key, value).commit()
    }

    override fun remove(key: String) {
        prefs.edit().remove(key).commit()
    }

    /**
     * Wipes the whole file.
     *
     * Called by the `export_and_delete` hard delete, which promises the record
     * is gone rather than hidden. Total rather than selective, for the reason
     * `UnplugStore.purge()` gives about its own file: a partial wipe is the
     * kind of thing that looks compliant and is not. This file belongs to the
     * shell alone, so there is nothing here that a wipe should spare.
     */
    override fun clear() {
        prefs.edit().clear().commit()
    }

    companion object {
        /** Separate from `unplug_shared_state`. See the class comment. */
        private const val NAME = "tether_shell_state"
    }
}
