// GENERATED from spec/screens/ca_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Diagnosis & plan  ·  route `/p/ca/onboarding/1`  ·  flow `ca`  ·  kind `screen`
/// Default state · program ca · phase onboarding
/// 
///
/// Actions (generated from spec/screens/ca_q1.json):
///   • Back → back
///   • Next → decide choice:ca_q1.has_plan: Has a written action plan? → Yes: push → ca_plan | No / Not sure: push → ca_noplan
/// API: —
class CaQ1Screen extends StatelessWidget {
  const CaQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.caQ1HeaderTitle, pill: s.caQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 2),
        TTitle(s.caQ1BodyN1Text),
        TBody(s.caQ1BodyN2Text, tone: TTextTone.muted),
        TRadioList(fieldKey: 'ca_q1.value', items: [TRadioItem(s.caQ1BodyN3ItemsN0Label, value: 'Asthma'), TRadioItem(s.caQ1BodyN3ItemsN1Label, value: 'COPD'), TRadioItem(s.caQ1BodyN3ItemsN2Label, value: 'Other lung condition'), TRadioItem(s.caQ1BodyN3ItemsN3Label, value: 'Not diagnosed: I want to learn')], selected: 0),
        TSegmented(fieldKey: 'ca_q1.has_plan', options: ['Yes', 'No', 'Not sure'], labels: [s.caQ1BodyN4OptionsN0, s.caQ1BodyN4OptionsN1, s.caQ1BodyN4OptionsN2], selected: 'Yes', label: s.caQ1BodyN4Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.caQ1FooterN0Label, onPressed: () => TNav.branch(context, 'Has a written action plan?', <String, VoidCallback>{'Yes': () => TNav.push(context, Routes.caPlan), 'No / Not sure': () => TNav.push(context, Routes.caNoplan)}, decide: 'choice:ca_q1.has_plan'), arrow: true),
      ],
    );
  }
}
