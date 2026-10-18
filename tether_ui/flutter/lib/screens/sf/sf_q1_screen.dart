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
    return TScreen(
      header: THeader(title: 'About your use', pill: '1 of 2'),
      children: [
        TSteps(n: 1, total: 2),
        TTitle('On a typical day, how long on social apps?'),
        TBody('A rough guess is fine.', tone: TTextTone.muted),
        TRadioList(fieldKey: 'sf_q1.value', items: [TRadioItem('Less than 1 hour'), TRadioItem('1–2 hours'), TRadioItem('3–4 hours'), TRadioItem('5+ hours')], selected: 2),
        TChips(fieldKey: 'sf_q1.which_pull_hardest_categories_on', options: ['Short video', 'Feeds', 'Messaging', 'Games', 'News'], selected: ['Short video', 'Feeds'], label: 'Which pull hardest? (categories only)'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.push(context, Routes.sfQ2), arrow: true),
      ],
    );
  }
}
