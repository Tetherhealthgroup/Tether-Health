// GENERATED from spec/screens/bf_q2.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Baseline: triggers  ·  route `/p/bf/onboarding/2`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase onboarding
/// 
///
/// Actions (generated from spec/screens/bf_q2.json):
///   • Back → back
///   • Next → push → bf_q3
/// API: —
class BfQ2Screen extends StatelessWidget {
  const BfQ2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your triggers', pill: '2 of 3'),
      children: [
        TSteps(n: 2, total: 3),
        TEyebrow('Choose all that apply'),
        TTitle('When do you most want a cigarette?'),
        TChips(fieldKey: 'bf_q2.value', options: ['Stress', 'After meals', 'Driving', 'With coffee', 'Social', 'Work breaks', 'Alcohol', 'Boredom', 'Morning', 'Scrolling'], selected: ['Stress', 'After meals', 'Driving', 'With coffee']),
        TField(fieldKey: 'bf_q2.add_your_own', label: 'Add your own', placeholder: 'Type another situation…'),
        TBody('Used to prepare, never to monitor. No background location.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.push(context, Routes.bfQ3), arrow: true),
      ],
    );
  }
}
