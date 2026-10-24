// GENERATED from spec/screens/nu_habit.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Weekly habit  ·  route `/p/nu/plan`  ·  flow `nu`  ·  kind `screen`
/// Default state · program nu · phase plan
/// 
///
/// Actions (generated from spec/screens/nu_habit.json):
///   • Back → back
///   • Start this habit → PUT /v1/program-data/nu/habit then replace → nu_home (onboarding: ob_setup)
/// API: —
class NuHabitScreen extends StatelessWidget {
  const NuHabitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.nuHabitHeaderTitle, pill: s.nuHabitHeaderPill),
      children: [
        TTitle(s.nuHabitBodyN0Text),
        TRadioList(fieldKey: 'nu_habit.value', items: [TRadioItem(s.nuHabitBodyN1ItemsN0Label, value: 'Add a vegetable to dinner', sub: s.nuHabitBodyN1ItemsN0Sub, badge: s.nuHabitBodyN1ItemsN0Badge), TRadioItem(s.nuHabitBodyN1ItemsN1Label, value: 'Water before each meal', sub: s.nuHabitBodyN1ItemsN1Sub), TRadioItem(s.nuHabitBodyN1ItemsN2Label, value: 'Cook at home', sub: s.nuHabitBodyN1ItemsN2Sub), TRadioItem(s.nuHabitBodyN1ItemsN3Label, value: '10-minute walk after a meal', sub: s.nuHabitBodyN1ItemsN3Sub)], selected: 0, bind: 'nu.habit.habit', bindClass: TBindClass.plan),
        TCard(children: [TToggleRow(fieldKey: 'nu_habit.track_weight', label: s.nuHabitBodyN2ChildrenN0Label, sub: s.nuHabitBodyN2ChildrenN0Sub, bind: 'nu.habit.track_weight', bindClass: TBindClass.plan)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.nuHabitFooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/nu/habit', screenId: 'nu_habit', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.nuHome))), arrow: true),
      ],
    );
  }
}
