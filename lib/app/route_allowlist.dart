// Which tether_ui screens may open from outside the app's own navigation.
//
// The generated screens move between each other by route name. Names can
// also arrive from outside that navigation:
// - a link that opens the app: the platform pushes it to the navigator as a
//   route;
// - the app's own runtime entries: a session that expired, a safety alert.
//
// Only the entries listed here may open that way. A pushed link never opens
// a screen: the one link the app registers is the sign-in callback, which
// the sign-in client handles itself (the password-reset screen then opens as
// the entry screen). Every other pushed name opens nothing and the member
// stays where they are; a cold start always opens on the resolved entry.
import 'package:flutter/widgets.dart';
import 'package:tether_ui/router/routes.dart';

import '../auth/auth_deep_link.dart';

/// The screens the entry resolver can open the app on.
const Set<String> entryRoutes = {
  Routes.welcome,
  Routes.today,
  Routes.accountDeleted,
  Routes.authNewpass,
  Routes.sysUpdate,
};

/// Runtime entries: screens that app code (never a link) opens on top of
/// everything, removing every other screen. Sheets open over the resolved
/// entry screen so closing them lands there.
const Set<String> runtimeEntryRoutes = {
  Routes.authSession,
  Routes.authSessionApple,
  Routes.authSessionGoogle,
  Routes.todaySafety,
};

/// Runtime entries that are sheets: they open over the entry screen.
const Set<String> runtimeEntrySheets = {
  Routes.authSession,
  Routes.authSessionApple,
  Routes.authSessionGoogle,
};

/// Whether app code may open [name] as the entry screen or a runtime entry.
bool isAllowedEntry(String name) =>
    entryRoutes.contains(name) || runtimeEntryRoutes.contains(name);

/// What a link pushed by the platform is.
enum PushedRouteKind {
  /// The sign-in callback (email confirmation, password reset). The sign-in
  /// client reads it; no screen opens for it.
  authCallback,

  /// Anything else. No screen opens.
  refused,
}

/// The kind of a pushed [location] (a full link or a bare path).
PushedRouteKind classifyPushedRoute(String location) {
  final uri = Uri.tryParse(location);
  if (uri == null) return PushedRouteKind.refused;
  final callback = Uri.parse(authRedirectUrl);
  final isCallback =
      (uri.scheme == callback.scheme && uri.host == callback.host) ||
          (uri.scheme.isEmpty && uri.path == '/${callback.host}');
  return isCallback ? PushedRouteKind.authCallback : PushedRouteKind.refused;
}

/// Takes every route the platform pushes (a link that opened the app) before
/// the navigator sees it, and opens nothing for it. Install before the
/// `MaterialApp` so it runs first.
class PushedRouteGate with WidgetsBindingObserver {
  PushedRouteGate({this.onPushed});

  /// Told the kind of each pushed route (tests; never the link itself).
  final void Function(PushedRouteKind kind)? onPushed;

  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    _take(routeInformation.uri.toString());
    return Future<bool>.value(true);
  }

  void _take(String location) => onPushed?.call(classifyPushedRoute(location));
}
