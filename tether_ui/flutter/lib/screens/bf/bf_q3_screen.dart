// GENERATED from spec/screens/bf_q3.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Baseline: reasons  ·  route `/p/bf/onboarding/3`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase onboarding
/// 
///
/// Actions (generated from spec/screens/bf_q3.json):
///   • Back → back
///   • Save my reasons → push → bf_path
/// API: —
class BfQ3Screen extends StatelessWidget {
  const BfQ3Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your reasons', pill: '3 of 3'),
      children: [
        TSteps(n: 3, total: 3),
        TTitle('What are you quitting for?'),
        TBody('Choose all that matter. Your top reason appears when a craving hits.', tone: TTextTone.muted),
        TChips(fieldKey: 'bf_q3.value', options: ['Protect my family', 'Breathe easier', 'Save money', 'Feel in control', 'My health', 'Be there for my future'], selected: ['Protect my family', 'Breathe easier', 'Save money']),
        TCard(variant: TCardVariant.mint, eyebrow: 'When a craving hits', children: [TQuote('You chose this for your family. This feeling will pass.')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save my reasons', onPressed: () => TNav.push(context, Routes.bfPath), arrow: true),
      ],
    );
  }
}
