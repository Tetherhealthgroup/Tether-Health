// GENERATED from spec/screens/sf_week_unplug.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Weekly reflection · Unplug on (iPhone)  ·  route `/p/sf/week?state=unplug`  ·  flow `sf`  ·  kind `screen`
/// State: Unplug on · iPhone of sf_week · program sf · phase milestone
/// Copy needs clinical/legal review. Apple’s weekly report sits above the person’s own estimates, which are what Tether stores and charts.
///
/// Actions (generated from spec/screens/sf_week_unplug.json):
///   • Back → back
///   • Yes → toast “Goal set to 75 min” then back
///   • Stay at 90 → back
/// API: —
class SfWeekUnplugScreen extends StatelessWidget {
  const SfWeekUnplugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfWeekUnplugHeaderTitle, pill: 'ScrollFree'),
      children: [
        TTitle(s.sfWeekUnplugBodyN0Text),
        TNativeSlot(id: 'ios.deviceActivityReport.week', label: s.sfWeekUnplugBodyN1Label, caption: s.sfWeekUnplugBodyN1Caption, height: 200.0),
        TBoundValues(keys: const ['sf.minutes_week'], builder: (context, v) => TBarChart(values: v.series('sf.minutes_week', const [190.0, 160.0, 130.0, 0.0, 110.0, 95.0, 85.0]), color: TColors.program('sf'), missing: [3], target: 90.0, labels: [s.sfWeekUnplugBodyN2LabelsN0, s.sfWeekUnplugBodyN2LabelsN1, s.sfWeekUnplugBodyN2LabelsN2, s.sfWeekUnplugBodyN2LabelsN3, s.sfWeekUnplugBodyN2LabelsN4, s.sfWeekUnplugBodyN2LabelsN5, s.sfWeekUnplugBodyN2LabelsN6], title: s.sfWeekUnplugBodyN2Title, caption: s.sfWeekUnplugBodyN2Caption)),
        TBoundValues(keys: const ['sf.phone_free_nights', 'sf.urges_paused', 'sf.urges_put_down'], builder: (context, v) => TStatGrid(stats: [TStat(label: s.sfWeekUnplugBodyN3ItemsN0Label, value: v.text('sf.phone_free_nights', '5/7')), TStat(label: s.sfWeekUnplugBodyN3ItemsN1Label, value: v.text('sf.urges_paused', '11'), sub: v.text('sf.urges_put_down', s.sfWeekUnplugBodyN3ItemsN1Sub))])),
        TBoundValues(keys: const ['sf.insight', 'sf.you_said'], builder: (context, v) => TCard(variant: TCardVariant.mint, eyebrow: s.sfWeekUnplugBodyN4Eyebrow, text: v.text('sf.insight', s.sfWeekUnplugBodyN4Text), children: [TQuote(v.text('sf.you_said', s.sfWeekUnplugBodyN4ChildrenN0Text))])),
        TBoundValues(keys: const ['sf.next_week_suggestion'], builder: (context, v) => TCard(eyebrow: s.sfWeekUnplugBodyN5Eyebrow, title: v.text('sf.next_week_suggestion', s.sfWeekUnplugBodyN5Title), children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[5].children[0].items[0]'), label: s.sfWeekUnplugBodyN5ChildrenN0ItemsN0Label, onPressed: () => TNav.toast(context, s.sfWeekUnplugBodyN5ChildrenN0ItemsN0ActionValue, then: () => TNav.back(context)), small: true), TButton(key: const ValueKey('a:body[5].children[0].items[1]'), label: s.sfWeekUnplugBodyN5ChildrenN0ItemsN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary, small: true)])])),
      ],
    );
  }
}
