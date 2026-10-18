// GENERATED from spec/screens/re_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Risk check  ·  route `/p/re/onboarding/1`  ·  flow `re`  ·  kind `screen`
/// Default state · program re · phase onboarding
/// 
///
/// Actions (generated from spec/screens/re_q1.json):
///   • Back → back
///   • See what this means → push → re_result
/// API: —
class ReQ1Screen extends StatelessWidget {
  const ReQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Risk check', pill: '1 of 1'),
      children: [
        TSteps(n: 1, total: 1),
        TTitle('Do any of these apply?'),
        TBody('These raise the chance of kidney or liver problems.', tone: TTextTone.muted),
        TChips(fieldKey: 're_q1.value', options: ['Diabetes', 'High blood pressure', 'Heart disease', 'Family history of kidney disease', 'Regular alcohol', 'Hepatitis B or C', 'None'], selected: ['Diabetes', 'High blood pressure']),
        TSegmented(fieldKey: 're_q1.known_condition', options: ['Kidney', 'Liver', 'Both', 'No'], selected: 'No', label: 'Known condition?'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'See what this means', onPressed: () => TNav.push(context, Routes.reResult), arrow: true),
      ],
    );
  }
}
