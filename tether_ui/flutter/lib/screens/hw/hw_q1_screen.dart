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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.hwQ1HeaderTitle, pill: s.hwQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 2),
        TTitle(s.hwQ1BodyN1Text),
        TChips(fieldKey: 'hw_q1.value', options: ['High blood pressure', 'High cholesterol', 'Heart disease', 'Stroke', 'None of these'], labels: [s.hwQ1BodyN2OptionsN0, s.hwQ1BodyN2OptionsN1, s.hwQ1BodyN2OptionsN2, s.hwQ1BodyN2OptionsN3, s.hwQ1BodyN2OptionsN4], selected: ['High blood pressure']),
        TSegmented(fieldKey: 'hw_q1.do_you_have_a_home_bp_monitor', options: ['Yes', 'No', 'Not sure'], labels: [s.hwQ1BodyN3OptionsN0, s.hwQ1BodyN3OptionsN1, s.hwQ1BodyN3OptionsN2], selected: 'Yes', label: s.hwQ1BodyN3Label),
        TCard(variant: TCardVariant.mint, text: s.hwQ1BodyN4Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.hwQ1FooterN0Label, onPressed: () => TNav.push(context, Routes.hwTargets), arrow: true),
      ],
    );
  }
}
