// GENERATED from spec/screens/sf_week.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Weekly reflection  ·  route `/p/sf/week`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase milestone
/// 
///
/// Actions (generated from spec/screens/sf_week.json):
///   • Back → back
///   • Yes → toast “Goal set to 75 min” then back
///   • Stay at 90 → back
/// API: —
class SfWeekScreen extends StatelessWidget {
  const SfWeekScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfWeekHeaderTitle, pill: 'ScrollFree'),
      children: [
        TTitle(s.sfWeekBodyN0Text),
        TBoundValues(keys: const ['sf.minutes_week'], builder: (context, v) => TBarChart(values: v.series('sf.minutes_week', const [190.0, 160.0, 130.0, 0.0, 110.0, 95.0, 85.0]), color: TColors.program('sf'), missing: [3], target: 90.0, labels: [s.sfWeekBodyN1LabelsN0, s.sfWeekBodyN1LabelsN1, s.sfWeekBodyN1LabelsN2, s.sfWeekBodyN1LabelsN3, s.sfWeekBodyN1LabelsN4, s.sfWeekBodyN1LabelsN5, s.sfWeekBodyN1LabelsN6], title: s.sfWeekBodyN1Title, caption: s.sfWeekBodyN1Caption)),
        TBoundValues(keys: const ['sf.phone_free_nights', 'sf.urges_paused', 'sf.urges_put_down'], builder: (context, v) => TStatGrid(stats: [TStat(label: s.sfWeekBodyN2ItemsN0Label, value: v.text('sf.phone_free_nights', '5/7')), TStat(label: s.sfWeekBodyN2ItemsN1Label, value: v.text('sf.urges_paused', '11'), sub: v.text('sf.urges_put_down', s.sfWeekBodyN2ItemsN1Sub))])),
        TBoundValues(keys: const ['sf.insight', 'sf.you_said'], builder: (context, v) => TCard(variant: TCardVariant.mint, eyebrow: s.sfWeekBodyN3Eyebrow, text: v.text('sf.insight', s.sfWeekBodyN3Text), children: [TQuote(v.text('sf.you_said', s.sfWeekBodyN3ChildrenN0Text))])),
        TBoundValues(keys: const ['sf.next_week_suggestion'], builder: (context, v) => TCard(eyebrow: s.sfWeekBodyN4Eyebrow, title: v.text('sf.next_week_suggestion', s.sfWeekBodyN4Title), children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[4].children[0].items[0]'), label: s.sfWeekBodyN4ChildrenN0ItemsN0Label, onPressed: () => TNav.toast(context, s.sfWeekBodyN4ChildrenN0ItemsN0ActionValue, then: () => TNav.back(context)), small: true), TButton(key: const ValueKey('a:body[4].children[0].items[1]'), label: s.sfWeekBodyN4ChildrenN0ItemsN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary, small: true)])])),
      ],
    );
  }
}
