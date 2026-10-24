// GENERATED from spec/screens/sf_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Baseline: use  ·  route `/p/sf/onboarding/1`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase onboarding
/// 
///
/// Actions (generated from spec/screens/sf_q1.json):
///   • Back → back
///   • Next → push → sf_q2
/// API: —
class SfQ1Screen extends StatelessWidget {
  const SfQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfQ1HeaderTitle, pill: s.sfQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 2),
        TTitle(s.sfQ1BodyN1Text),
        TBody(s.sfQ1BodyN2Text, tone: TTextTone.muted),
        TRadioList(fieldKey: 'sf_q1.value', items: [TRadioItem(s.sfQ1BodyN3ItemsN0Label, value: 'Less than 1 hour'), TRadioItem(s.sfQ1BodyN3ItemsN1Label, value: '1–2 hours'), TRadioItem(s.sfQ1BodyN3ItemsN2Label, value: '3–4 hours'), TRadioItem(s.sfQ1BodyN3ItemsN3Label, value: '5+ hours')], selected: 2),
        TChips(fieldKey: 'sf_q1.which_pull_hardest_categories_on', options: ['Short video', 'Feeds', 'Messaging', 'Games', 'News'], labels: [s.sfQ1BodyN4OptionsN0, s.sfQ1BodyN4OptionsN1, s.sfQ1BodyN4OptionsN2, s.sfQ1BodyN4OptionsN3, s.sfQ1BodyN4OptionsN4], selected: ['Short video', 'Feeds'], label: s.sfQ1BodyN4Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfQ1FooterN0Label, onPressed: () => TNav.push(context, Routes.sfQ2), arrow: true),
      ],
    );
  }
}
