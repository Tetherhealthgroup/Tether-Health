// GENERATED from spec/screens/hw_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Baseline  ·  route `/p/hw/onboarding/1`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase onboarding
/// 
///
/// Actions (generated from spec/screens/hw_q1.json):
///   • Back → back
///   • Next → push → hw_targets
/// API: —
class HwQ1Screen extends StatelessWidget {
  const HwQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'About you', pill: '1 of 2'),
      children: [
        TSteps(n: 1, total: 2),
        TTitle('Has a clinician talked with you about…'),
        TChips(fieldKey: 'hw_q1.value', options: ['High blood pressure', 'High cholesterol', 'Heart disease', 'Stroke', 'None of these'], selected: ['High blood pressure']),
        TSegmented(fieldKey: 'hw_q1.do_you_have_a_home_bp_monitor', options: ['Yes', 'No', 'Not sure'], selected: 'Yes', label: 'Do you have a home BP monitor?'),
        TCard(variant: TCardVariant.mint, text: 'No monitor? Many pharmacies have free kiosks. We’ll show how to measure correctly.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.push(context, Routes.hwTargets), arrow: true),
      ],
    );
  }
}
