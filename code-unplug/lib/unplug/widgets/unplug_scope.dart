import 'package:flutter/widgets.dart';

import '../models/unplug_module_state.dart';

/// Makes one [UnplugModuleState] available to every Unplug screen.
///
/// Screens A–L share a single instance, so a template applied on L is visible
/// on F, and an authorization granted on B is visible on I.
class UnplugScope extends InheritedNotifier<UnplugModuleState> {
  const UnplugScope({
    required UnplugModuleState state,
    required super.child,
    super.key,
  }) : super(notifier: state);

  static UnplugModuleState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<UnplugScope>();
    assert(scope?.notifier != null, 'No UnplugScope found above this widget.');
    return scope!.notifier!;
  }
}
