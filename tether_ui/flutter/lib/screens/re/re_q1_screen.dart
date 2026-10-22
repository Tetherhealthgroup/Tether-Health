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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.reQ1HeaderTitle, pill: s.reQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 1),
        TTitle(s.reQ1BodyN1Text),
        TBody(s.reQ1BodyN2Text, tone: TTextTone.muted),
        TChips(fieldKey: 're_q1.value', options: ['Diabetes', 'High blood pressure', 'Heart disease', 'Family history of kidney disease', 'Regular alcohol', 'Hepatitis B or C', 'None'], labels: [s.reQ1BodyN3OptionsN0, s.reQ1BodyN3OptionsN1, s.reQ1BodyN3OptionsN2, s.reQ1BodyN3OptionsN3, s.reQ1BodyN3OptionsN4, s.reQ1BodyN3OptionsN5, s.reQ1BodyN3OptionsN6], selected: ['Diabetes', 'High blood pressure']),
        TSegmented(fieldKey: 're_q1.known_condition', options: ['Kidney', 'Liver', 'Both', 'No'], labels: [s.reQ1BodyN4OptionsN0, s.reQ1BodyN4OptionsN1, s.reQ1BodyN4OptionsN2, s.reQ1BodyN4OptionsN3], selected: 'No', label: s.reQ1BodyN4Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.reQ1FooterN0Label, onPressed: () => TNav.push(context, Routes.reResult), arrow: true),
      ],
    );
  }
}
