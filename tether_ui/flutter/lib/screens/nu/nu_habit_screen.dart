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
    return TScreen(
      header: THeader(title: 'This week’s habit', pill: 'Plan'),
      children: [
        TTitle('Pick one habit for this week.'),
        TRadioList(fieldKey: 'nu_habit.value', items: [TRadioItem('Add a vegetable to dinner', sub: '5 nights this week', badge: 'Suggested'), TRadioItem('Water before each meal', sub: 'Every day'), TRadioItem('Cook at home', sub: '3 times this week'), TRadioItem('10-minute walk after a meal', sub: '4 times')], selected: 0, bind: 'nu.habit.habit'),
        TCard(children: [TToggleRow(fieldKey: 'nu_habit.track_weight', label: 'Track weight', sub: 'Off by default · can stay off forever', bind: 'nu.habit.track_weight')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Start this habit', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/nu/habit', screenId: 'nu_habit', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.nuHome))), arrow: true),
      ],
    );
  }
}
