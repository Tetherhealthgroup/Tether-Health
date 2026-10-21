// Tells the endpoint registry which screen instance submits.
import 'package:flutter/widgets.dart';
import 'package:tether_ui/router/app_router.dart';

/// Watches the tether_ui navigator and gives each route a number of its own,
/// so a submit can be tied to the screen instance it came from.
class ScreenInstances extends NavigatorObserver {
  /// Route name by screen id, from the generated catalog.
  static final Map<String, String> _routeOfScreen = {
    for (final (id, _, _, route) in AppRouter.catalog) id: route,
  };

  final Expando<int> _numbers = Expando<int>('screen instance');
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];
  int _next = 0;

  /// The routes in the navigator, bottom first.
  List<Route<dynamic>> get stack => List<Route<dynamic>>.unmodifiable(_stack);

  /// The number of the topmost open instance of [screenId], or null when no
  /// open route shows that screen. A submit runs on the screen the member
  /// tapped, which is that topmost instance even when a safety screen has
  /// just opened above it.
  int? instanceOf(String screenId) {
    final route = _routeOfScreen[screenId];
    if (route == null) return null;
    for (final open in _stack.reversed) {
      if (open.settings.name == route) return _numberOf(open);
    }
    return null;
  }

  int _numberOf(Route<dynamic> route) => _numbers[route] ??= ++_next;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _numberOf(route);
    _stack.add(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _stack.remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute == null) {
      if (index >= 0) _stack.removeAt(index);
      return;
    }
    _numberOf(newRoute);
    if (index >= 0) {
      _stack[index] = newRoute;
    } else {
      _stack.add(newRoute);
    }
  }
}
