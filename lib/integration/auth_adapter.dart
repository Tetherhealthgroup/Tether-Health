// Native sign-in (Apple, Google) for the tether_ui screens, built from the
// app's backend.
//
// Not wired yet: provider branches fail closed.
import 'package:tether_ui/ui/ui.dart';

import '../backend/backend.dart';
import '../config/app_config.dart';

/// The kit's sign-in hook for [backend], or null when native sign-in is not
/// available.
TAuth? buildAuth(Backend backend, AppConfig config) => null;
