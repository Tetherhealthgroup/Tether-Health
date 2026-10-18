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
    return TScreen(
      header: THeader(title: 'About your breathing', pill: '1 of 2'),
      children: [
        TSteps(n: 1, total: 2),
        TTitle('Which applies to you?'),
        TBody('As told by a clinician.', tone: TTextTone.muted),
        TRadioList(fieldKey: 'ca_q1.value', items: [TRadioItem('Asthma'), TRadioItem('COPD'), TRadioItem('Other lung condition'), TRadioItem('Not diagnosed: I want to learn')], selected: 0),
        TSegmented(fieldKey: 'ca_q1.has_plan', options: ['Yes', 'No', 'Not sure'], selected: 'Yes', label: 'Do you have a written action plan?'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.branch(context, 'Has a written action plan?', <String, VoidCallback>{'Yes': () => TNav.push(context, Routes.caPlan), 'No / Not sure': () => TNav.push(context, Routes.caNoplan)}, decide: 'choice:ca_q1.has_plan'), arrow: true),
      ],
    );
  }
}
