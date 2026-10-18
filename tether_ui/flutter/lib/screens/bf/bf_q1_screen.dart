// GENERATED from spec/screens/bf_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Baseline: amount  ·  route `/p/bf/onboarding/1`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase onboarding
/// 
///
/// Actions (generated from spec/screens/bf_q1.json):
///   • Back → back
///   • Next → push → bf_q2
/// API: —
class BfQ1Screen extends StatelessWidget {
  const BfQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'About your smoking', pill: '1 of 3'),
      children: [
        TSteps(n: 1, total: 3),
        TEyebrow('Question 1 of 3'),
        TTitle('On a typical day, how many cigarettes?'),
        TRadioList(fieldKey: 'bf_q1.value', items: [TRadioItem('I don’t smoke every day'), TRadioItem('10 or fewer'), TRadioItem('11–20'), TRadioItem('21–30'), TRadioItem('31 or more')], selected: 2),
        TCard(variant: TCardVariant.mint, title: 'Why we ask', text: 'Tailors your plan and estimates money saved. Not a diagnosis.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.push(context, Routes.bfQ2), arrow: true),
      ],
    );
  }
}
