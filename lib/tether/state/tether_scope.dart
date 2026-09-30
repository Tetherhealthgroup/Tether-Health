import 'package:flutter/widgets.dart';

import 'tether_session.dart';

/// Makes one [TetherSession] available to every screen in every program.
///
/// One instance for the whole shell, not one per program. `SH5` has to show
/// what each program shares side by side, and `SH4` has to export across all
/// of them, so a per-program store would only have to be joined back together
/// at exactly the two screens that matter most.
class TetherScope extends InheritedNotifier<TetherSession> {
  const TetherScope({
    required TetherSession session,
    required super.child,
    super.key,
  }) : super(notifier: session);

  static TetherSession of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<TetherScope>();
    assert(scope?.notifier != null, 'No TetherScope found above this widget.');
    return scope!.notifier!;
  }
}
