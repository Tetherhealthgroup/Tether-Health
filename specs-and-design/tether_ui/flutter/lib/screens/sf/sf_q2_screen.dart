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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfQ2HeaderTitle, pill: s.sfQ2HeaderPill),
      children: [
        TSteps(n: 2, total: 2),
        TTitle(s.sfQ2BodyN1Text),
        TChips(fieldKey: 'sf_q2.value', options: ['Bored', 'Lonely', 'In bed', 'Avoiding work', 'After conflict', 'Waiting', 'Can’t sleep', 'First thing'], labels: [s.sfQ2BodyN2OptionsN0, s.sfQ2BodyN2OptionsN1, s.sfQ2BodyN2OptionsN2, s.sfQ2BodyN2OptionsN3, s.sfQ2BodyN2OptionsN4, s.sfQ2BodyN2OptionsN5, s.sfQ2BodyN2OptionsN6, s.sfQ2BodyN2OptionsN7], selected: ['Bored', 'In bed', 'Avoiding work']),
        TSegmented(fieldKey: 'sf_q2.how_do_you_usually_feel_after', options: ['Better', 'Same', 'Worse'], labels: [s.sfQ2BodyN3OptionsN0, s.sfQ2BodyN3OptionsN1, s.sfQ2BodyN3OptionsN2], selected: 'Worse', label: s.sfQ2BodyN3Label),
        TBody(s.sfQ2BodyN4Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfQ2FooterN0Label, onPressed: () => TNav.push(context, Routes.sfGoal), arrow: true),
      ],
    );
  }
}
