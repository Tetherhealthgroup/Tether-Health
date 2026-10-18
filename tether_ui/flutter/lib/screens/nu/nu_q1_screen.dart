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
    return TScreen(
      header: THeader(title: 'What matters', pill: '1 of 1'),
      children: [
        TSteps(n: 1, total: 1),
        TTitle('What would you like more of?'),
        TChips(fieldKey: 'nu_q1.value', options: ['Energy', 'Easy meals', 'More plants', 'More water', 'Move more', 'Save on food', 'Feel better about food'], selected: ['Energy', 'Easy meals', 'More water']),
        TCard(title: 'Have you struggled with eating, like restricting, bingeing or purging?', text: 'If yes, we adjust Nourish and share support options.', children: [TSegmented(fieldKey: 'nu_q1.eating', options: ['No', 'Yes', 'Prefer not to say'], selected: 'No')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.branch(context, 'Eating-history answer', <String, VoidCallback>{'No': () => TNav.push(context, Routes.nuHabit), 'Yes / Prefer not to say': () => TNav.push(context, Routes.nuProtect)}, decide: 'choice:nu_q1.eating'), arrow: true),
      ],
    );
  }
}
