// The shell's key/value store contract.
//
// This file is the single source of truth for how the Tether shell reaches
// durable storage. Run tool/generate_pigeon.sh after any change; the generated
// Dart, Swift and Kotlin are checked in and must never be edited by hand.
//
// It is a second contract rather than four more methods on
// pigeons/unplug_api.dart, because that file is the Unplug module's
// screen-time boundary: authorization, shields, sessions, usage. Shell storage
// is not screen-time state, it is not read by the three iOS extensions, and
// putting it there would mean every regeneration of the shell's storage
// contract also rewrites the intercept's. Two contracts cost one extra file;
// one contract costs a coupling that nobody notices until it has to be undone.
//
// Keep this surface as small as it is. The app has exactly one runtime
// dependency — the Flutter SDK — and `test/no_third_party_sdks_test.dart`
// fails the build if a second appears, so `shared_preferences` is not an
// option and this channel is the whole of the shell's persistence layer. That
// is an argument for a boring store, not a clever one: `TetherSession` already
// knows how to turn itself into JSON, so the platform never needs to know what
// an enrolment is. It stores strings. Every decision about shape, schema and
// migration stays in Dart, where it is testable without a device.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'lib/tether/platform/tether_store_api.g.dart',
    dartOptions: DartOptions(),
    swiftOut: 'ios/Runner/Store/TetherStoreApi.g.swift',
    // Renamed because both generated Swift files compile into the Runner
    // target and Pigeon emits its error class at file scope. Left at the
    // default, the second contract is an invalid redeclaration of
    // `PigeonError` and the app does not build. The alternative Pigeon offers
    // — `includeErrorClass: false`, and share the Unplug file's copy — would
    // make this contract stop compiling if the Unplug one were ever removed,
    // which is a dependency between two files that are meant to have none.
    swiftOptions: SwiftOptions(errorClassName: 'TetherStoreError'),
    kotlinOut:
        'android/app/src/main/kotlin/com/TetherHealthLLC/tetherhealth/store/TetherStoreApi.g.kt',
    kotlinOptions: KotlinOptions(
      package: 'com.TetherHealthLLC.tetherhealth.store',
    ),
    dartPackageName: 'tether_health',
  ),
)
/// Durable key/value storage for the shell, owned by the platform.
///
/// Synchronous on purpose. Both implementations are a `UserDefaults` or a
/// `SharedPreferences` read, which are memory lookups after the first touch,
/// and making them `@async` would buy nothing but a suspend function on each
/// side. Dart still sees futures — every Pigeon host call is asynchronous from
/// Dart regardless — so the restore-before-first-frame path is unaffected.
///
/// There is no `isSupported()` here, unlike `UnplugHostApi`. A store either
/// answers or it does not, and the Dart side treats a throwing channel as
/// "no platform" — see `lib/tether/state/session_store.dart`. Adding a probe
/// method would mean two ways for the same absence to be reported.
@HostApi()
abstract class TetherStoreApi {
  /// The value written under [key], or null when nothing is stored there.
  ///
  /// Null is the answer for "never written" as well as for "removed". The
  /// shell has no use for the difference: a missing snapshot and a deleted one
  /// both mean the session starts empty.
  String? read(String key);

  void write(String key, String value);

  void remove(String key);

  /// Wipes every key this store owns.
  ///
  /// Exists for the `export_and_delete` safeguard, which asks that deletion be
  /// "completed rather than hidden". [remove] would be enough for today's one
  /// key; [clear] is what stays correct when a second key is added and someone
  /// forgets to extend the delete path.
  void clear();
}
