// GENERATED from spec/screens/nu_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Goals & screen  ·  route `/p/nu/onboarding/1`  ·  flow `nu`  ·  kind `screen`
/// Default state · program nu · phase onboarding
/// 
///
/// Actions (generated from spec/screens/nu_q1.json):
///   • Back → back
///   • Next → decide choice:nu_q1.eating: Eating-history answer → No: push → nu_habit | Yes / Prefer not to say: push → nu_protect
/// API: —
class NuQ1Screen extends StatelessWidget {
  const NuQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.nuQ1HeaderTitle, pill: s.nuQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 1),
        TTitle(s.nuQ1BodyN1Text),
        TChips(fieldKey: 'nu_q1.value', options: ['Energy', 'Easy meals', 'More plants', 'More water', 'Move more', 'Save on food', 'Feel better about food'], labels: [s.nuQ1BodyN2OptionsN0, s.nuQ1BodyN2OptionsN1, s.nuQ1BodyN2OptionsN2, s.nuQ1BodyN2OptionsN3, s.nuQ1BodyN2OptionsN4, s.nuQ1BodyN2OptionsN5, s.nuQ1BodyN2OptionsN6], selected: ['Energy', 'Easy meals', 'More water']),
        TCard(title: s.nuQ1BodyN3Title, text: s.nuQ1BodyN3Text, children: [TSegmented(fieldKey: 'nu_q1.eating', options: ['No', 'Yes', 'Prefer not to say'], labels: [s.nuQ1BodyN3ChildrenN0OptionsN0, s.nuQ1BodyN3ChildrenN0OptionsN1, s.nuQ1BodyN3ChildrenN0OptionsN2], selected: 'No')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.nuQ1FooterN0Label, onPressed: () => TNav.branch(context, 'Eating-history answer', <String, VoidCallback>{'No': () => TNav.push(context, Routes.nuHabit), 'Yes / Prefer not to say': () => TNav.push(context, Routes.nuProtect)}, decide: 'choice:nu_q1.eating'), arrow: true),
      ],
    );
  }
}
