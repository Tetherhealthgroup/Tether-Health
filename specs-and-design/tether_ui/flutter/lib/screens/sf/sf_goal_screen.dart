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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfGoalHeaderTitle, pill: s.sfGoalHeaderPill),
      children: [
        TTitle(s.sfGoalBodyN0Text),
        TBoundValues(keys: const ['sf.baseline_line'], place: TExamplePlace.inline, builder: (context, v) => TBody(v.text('sf.baseline_line', s.sfGoalBodyN1Text), tone: TTextTone.muted)),
        TCard(children: [TSliderField(fieldKey: 'sf_goal.daily_social_time', label: s.sfGoalBodyN2ChildrenN0Label, value: 90.0, min: 30.0, max: 240.0, minLabel: s.sfGoalBodyN2ChildrenN0MinLabel, maxLabel: s.sfGoalBodyN2ChildrenN0MaxLabel, color: TColors.program('sf'), suffix: ' min'), TToggleRow(fieldKey: 'sf_goal.step_down_15_min_each_week', label: s.sfGoalBodyN2ChildrenN1Label, value: true)]),
        TCard(eyebrow: s.sfGoalBodyN3Eyebrow, children: [TChecklist(items: [TCheckItem(s.sfGoalBodyN3ChildrenN0ItemsN0Label, value: 'Bedtime', sub: s.sfGoalBodyN3ChildrenN0ItemsN0Sub, done: true), TCheckItem(s.sfGoalBodyN3ChildrenN0ItemsN1Label, value: 'Meals', sub: s.sfGoalBodyN3ChildrenN0ItemsN1Sub, done: true), TCheckItem(s.sfGoalBodyN3ChildrenN0ItemsN2Label, value: 'First hour awake')])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: s.sfGoalBodyN4RowsN0Label, sub: s.sfGoalBodyN4RowsN0Sub, onTap: () => TNav.push(context, Routes.sfScreentime))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfGoalFooterN0Label, onPressed: () => TNav.push(context, Routes.sfBuddy), arrow: true),
      ],
    );
  }
}
