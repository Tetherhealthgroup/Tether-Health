import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {

  /// The iOS half of the Unplug channel (addendum §2.3).
  ///
  /// Held here rather than created on demand so the very first `isSupported()`
  /// from Dart has something to answer it. Without that the module would fall
  /// back to its simulation on a build that does have a screen-time layer, and
  /// show made-up numbers as though they were measurements.
  private var unplug: AnyObject?

  /// The iOS half of the shell's key/value store.
  ///
  /// Unconditional, unlike `unplug`: there is no OS version below which
  /// `UserDefaults` is unavailable, and the shell restores the saved session
  /// before its first frame. A store registered any later than this reads, from
  /// Dart, as a store that is not there — and the shell would take that as an
  /// instruction to start the person off with an empty record.
  private var store: TetherStore?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    store = TetherStore(
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )

    // FamilyControls, ManagedSettings and DeviceActivity are all iOS 16+. On
    // anything older the host is simply not installed, `isSupported()` never
    // answers, and Dart runs its own simulation — which is the honest outcome
    // for a device that cannot do this at all.
    if #available(iOS 16.0, *) {
      let host = UnplugHost(
        binaryMessenger: engineBridge.applicationRegistrar.messenger(),
        controller: window?.rootViewController
      )
      unplug = host
    }
  }

  override func applicationDidBecomeActive(_ application: UIApplication) {
    super.applicationDidBecomeActive(application)
    // The extensions queue what happened while the app was closed, because they
    // cannot reach Flutter themselves. This is where that queue is drained.
    if #available(iOS 16.0, *) {
      (unplug as? UnplugHost)?.drainPendingEvents()
    }
  }
}
