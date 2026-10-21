// Routes the app builds itself in the tether_ui shell.
import 'package:flutter/widgets.dart';

/// Routes the app builds itself (not generated screens), by route name. Each
/// one builds on `TScreen` or `TSheet`, or wraps its content in
/// `TFallbackInset`, so the call fallback never covers its primary button
/// (test/app/app_owned_routes_test.dart checks every entry). None yet.
const Map<String, WidgetBuilder> appOwnedRoutes = <String, WidgetBuilder>{};
