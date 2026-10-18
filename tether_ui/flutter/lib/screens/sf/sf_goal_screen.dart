// GENERATED from spec/screens/sf_goal.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Goal & windows  ·  route `/p/sf/plan/goal`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase plan
/// 
///
/// Actions (generated from spec/screens/sf_goal.json):
///   • Back → back
///   • Connect Screen Time → push → sf_screentime
///   • Save my goal → push → sf_buddy
/// API: —
class SfGoalScreen extends StatelessWidget {
  const SfGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your goal', pill: 'Plan'),
      children: [
        TTitle('Set a goal that feels doable.'),
        TBody('From about 3 hours a day.', tone: TTextTone.muted),
        TCard(children: [TSliderField(fieldKey: 'sf_goal.daily_social_time', label: 'Daily social time', value: 90.0, min: 30.0, max: 240.0, minLabel: '30 min', maxLabel: '4 h', color: TColors.program('sf'), suffix: ' min'), TToggleRow(fieldKey: 'sf_goal.step_down_15_min_each_week', label: 'Step down 15 min each week', value: true)]),
        TCard(eyebrow: 'App-free times', children: [TChecklist(items: [TCheckItem('Bedtime', sub: '10:00 PM – 7:00 AM', done: true), TCheckItem('Meals', sub: 'When you mark a meal', done: true), TCheckItem('First hour awake')])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: 'Connect Screen Time', sub: 'Optional · totals only', onTap: () => TNav.push(context, Routes.sfScreentime))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save my goal', onPressed: () => TNav.push(context, Routes.sfBuddy), arrow: true),
      ],
    );
  }
}
