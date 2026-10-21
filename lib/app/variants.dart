// Platform variants of the tether_ui routes.
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:tether_ui/router/app_router.dart';
import 'package:tether_ui/router/routes.dart';

import 'app_owned_routes.dart';

/// On Android these routes open as their Android variant. Nothing is
/// substituted on iOS. Sign-in-method variants are chosen elsewhere.
const Map<String, String> androidRouteVariants = {
  Routes.sysUpdate: Routes.sysUpdateAndroid,
  Routes.sfScreentime: Routes.sfScreentimeAndroid,
  Routes.sfHomeUnplug: Routes.sfHomeUnplugAndroid,
  // The base route only; its other states are not substituted.
  Routes.sfUnplugHealth: Routes.sfUnplugHealthAndroid,
};

/// The route name actually opened for [name] on [platform].
String variantRouteName(String name, TargetPlatform platform) =>
    platform == TargetPlatform.android
        ? androidRouteVariants[name] ?? name
        : name;

/// The app's route factory for the tether_ui screens: the app-owned routes,
/// then the generated router with the platform variants applied. The route
/// settings carry the variant name. Unknown names (the developer gallery
/// included) give null.
Route<dynamic>? generateAppRoute(
  RouteSettings settings, {
  TargetPlatform? platform,
}) {
  final name = settings.name;
  final appOwned = appOwnedRoutes[name];
  if (appOwned != null) {
    return MaterialPageRoute<void>(builder: appOwned, settings: settings);
  }
  if (name == null || !AppRouter.screens.containsKey(name)) return null;
  final opened = variantRouteName(name, platform ?? defaultTargetPlatform);
  return AppRouter.onGenerateRoute(
    opened == name
        ? settings
        : RouteSettings(name: opened, arguments: settings.arguments),
  );
}
