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
    return TScreen(
      header: THeader(title: 'Week 2', pill: 'ScrollFree'),
      children: [
        TTitle('Your week, honestly.'),
        TBarChart(values: [190.0, 160.0, 130.0, 0.0, 110.0, 95.0, 85.0], color: TColors.program('sf'), missing: [3], target: 90.0, labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'], title: 'Social minutes / day', caption: 'Thursday: no check-in · not counted as zero'),
        TStatGrid(stats: [TStat(label: 'Phone-free nights', value: '5/7'), TStat(label: 'Urges paused', value: '11', sub: '7 put down')]),
        TCard(variant: TCardVariant.mint, eyebrow: 'You said', text: '“Drained” was 4× less common on phone-free nights.', children: [TQuote('I feel drained after long scrolls.')]),
        TCard(eyebrow: 'Next week', title: 'Step down to 75 min?', children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[4].children[0].items[0]'), label: 'Yes', onPressed: () => TNav.toast(context, 'Goal set to 75 min', then: () => TNav.back(context)), small: true), TButton(key: const ValueKey('a:body[4].children[0].items[1]'), label: 'Stay at 90', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary, small: true)])]),
      ],
    );
  }
}
