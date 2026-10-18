// GENERATED from spec/screens/sf_q2.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Baseline: triggers  ·  route `/p/sf/onboarding/2`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase onboarding
/// 
///
/// Actions (generated from spec/screens/sf_q2.json):
///   • Back → back
///   • Next → push → sf_goal
/// API: —
class SfQ2Screen extends StatelessWidget {
  const SfQ2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your triggers', pill: '2 of 2'),
      children: [
        TSteps(n: 2, total: 2),
        TTitle('When do you reach for it?'),
        TChips(fieldKey: 'sf_q2.value', options: ['Bored', 'Lonely', 'In bed', 'Avoiding work', 'After conflict', 'Waiting', 'Can’t sleep', 'First thing'], selected: ['Bored', 'In bed', 'Avoiding work']),
        TSegmented(fieldKey: 'sf_q2.how_do_you_usually_feel_after', options: ['Better', 'Same', 'Worse'], selected: 'Worse', label: 'How do you usually feel after?'),
        TBody('Used for your plan only. ScrollFree never reads what you look at.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.push(context, Routes.sfGoal), arrow: true),
      ],
    );
  }
}
