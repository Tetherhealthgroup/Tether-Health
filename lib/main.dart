import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'prototype/prototype_app.dart';
import 'tether/tether_app.dart';

/// Re-exported so the existing prototype tests keep importing it from here.
///
/// The class moved to `lib/prototype/prototype_app.dart` when the shell became
/// the entry point; moving a widget should not break a test that was asserting
/// something true about it.
export 'prototype/prototype_app.dart' show TetherHealthApp;

/// Which app to launch.
///
/// Defaults to the shell. The bitmap prototype is still buildable because the
/// 28 approved screens are the signed-off reference for the cessation
/// programme and a native rebuild of them has not been reviewed against the
/// artwork:
///
///     flutter run --dart-define=TETHER_ENTRY=prototype
const _entry = String.fromEnvironment('TETHER_ENTRY', defaultValue: 'shell');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const isPrototype = _entry == 'prototype';

  if (!kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.android)) {
    // The prototype is full-bleed 1290 × 2796 artwork, so it hides the system
    // bars to show the picture as drawn. The shell is a real app and keeps
    // them: hiding the clock and the battery on something somebody uses at
    // 11pm is a cost with nothing on the other side of it.
    if (isPrototype) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    }
    await SystemChrome.setPreferredOrientations(
      const [DeviceOrientation.portraitUp],
    );
  }

  runApp(isPrototype ? const TetherHealthApp() : const TetherApp());
}
