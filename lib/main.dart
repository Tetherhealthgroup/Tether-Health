import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth/account_controller.dart';
import 'auth/auth_gateway.dart';
import 'auth/secure_session_storage.dart';
import 'config/app_config.dart';
import 'profile/profile_api_client.dart';
import 'profile/profile_repository.dart';
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

  // Supabase and the account controller, from develop. Both are optional: an
  // unconfigured build runs exactly as it did before, which is what keeps
  // `flutter run` working for anybody without the dart-defines.
  final config = AppConfig.fromEnvironment();
  AccountController? account;
  if (config.hasAnyConfiguration) config.validate();
  if (config.isConfigured) {
    await Supabase.initialize(
      url: config.supabaseUrl,
      publishableKey: config.supabaseAnonKey,
      authOptions: FlutterAuthClientOptions(
        localStorage: SecureSessionStorage(),
      ),
    );
    final auth = SupabaseAuthGateway(Supabase.instance.client);
    account = AccountController(
      auth: auth,
      profiles: ProfileRepository(
        auth: auth,
        api: HttpProfileApiClient(baseUrl: config.apiBaseUrl),
      ),
    );
  }

  // The account controller goes to the prototype, which is the flow develop
  // built it for. The Tether shell has its own persistence and does not yet
  // read it — wiring sign-in to the shell is separate work, and pretending
  // otherwise here would give the shell a signed-in state it never uses.
  runApp(
    isPrototype
        ? TetherHealthApp(accountController: account)
        : const TetherApp(),
  );
}
