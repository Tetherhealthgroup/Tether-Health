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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfQ1HeaderTitle, pill: s.bfQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 3),
        TEyebrow(s.bfQ1BodyN1Text),
        TTitle(s.bfQ1BodyN2Text),
        TRadioList(fieldKey: 'bf_q1.value', items: [TRadioItem(s.bfQ1BodyN3ItemsN0Label, value: 'I don’t smoke every day'), TRadioItem(s.bfQ1BodyN3ItemsN1Label, value: '10 or fewer'), TRadioItem('11–20'), TRadioItem('21–30'), TRadioItem(s.bfQ1BodyN3ItemsN4Label, value: '31 or more')], selected: 2),
        TCard(variant: TCardVariant.mint, title: s.bfQ1BodyN4Title, text: s.bfQ1BodyN4Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfQ1FooterN0Label, onPressed: () => TNav.push(context, Routes.bfQ2), arrow: true),
      ],
    );
  }
}
