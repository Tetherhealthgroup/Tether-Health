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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfQ2HeaderTitle, pill: s.bfQ2HeaderPill),
      children: [
        TSteps(n: 2, total: 3),
        TEyebrow(s.bfQ2BodyN1Text),
        TTitle(s.bfQ2BodyN2Text),
        TChips(fieldKey: 'bf_q2.value', options: ['Stress', 'After meals', 'Driving', 'With coffee', 'Social', 'Work breaks', 'Alcohol', 'Boredom', 'Morning', 'Scrolling'], labels: [s.bfQ2BodyN3OptionsN0, s.bfQ2BodyN3OptionsN1, s.bfQ2BodyN3OptionsN2, s.bfQ2BodyN3OptionsN3, s.bfQ2BodyN3OptionsN4, s.bfQ2BodyN3OptionsN5, s.bfQ2BodyN3OptionsN6, s.bfQ2BodyN3OptionsN7, s.bfQ2BodyN3OptionsN8, s.bfQ2BodyN3OptionsN9], selected: ['Stress', 'After meals', 'Driving', 'With coffee']),
        TField(fieldKey: 'bf_q2.add_your_own', label: s.bfQ2BodyN4Label, placeholder: s.bfQ2BodyN4Placeholder),
        TBody(s.bfQ2BodyN5Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfQ2FooterN0Label, onPressed: () => TNav.push(context, Routes.bfQ3), arrow: true),
      ],
    );
  }
}
