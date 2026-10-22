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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfQ3HeaderTitle, pill: s.bfQ3HeaderPill),
      children: [
        TSteps(n: 3, total: 3),
        TTitle(s.bfQ3BodyN1Text),
        TBody(s.bfQ3BodyN2Text, tone: TTextTone.muted),
        TChips(fieldKey: 'bf_q3.value', options: ['Protect my family', 'Breathe easier', 'Save money', 'Feel in control', 'My health', 'Be there for my future'], labels: [s.bfQ3BodyN3OptionsN0, s.bfQ3BodyN3OptionsN1, s.bfQ3BodyN3OptionsN2, s.bfQ3BodyN3OptionsN3, s.bfQ3BodyN3OptionsN4, s.bfQ3BodyN3OptionsN5], selected: ['Protect my family', 'Breathe easier', 'Save money']),
        TCard(variant: TCardVariant.mint, eyebrow: s.bfQ3BodyN4Eyebrow, children: [TQuote(s.bfQ3BodyN4ChildrenN0Text)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfQ3FooterN0Label, onPressed: () => TNav.push(context, Routes.bfPath), arrow: true),
      ],
    );
  }
}
