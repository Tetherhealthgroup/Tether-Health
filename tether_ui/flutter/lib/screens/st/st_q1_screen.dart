// GENERATED from spec/screens/st_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Type & device  ·  route `/p/st/onboarding/1`  ·  flow `st`  ·  kind `screen`
/// Default state · program st · phase onboarding
/// 
///
/// Actions (generated from spec/screens/st_q1.json):
///   • Back → back
///   • Next → push → st_range
/// API: —
class StQ1Screen extends StatelessWidget {
  const StQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'About you', pill: '1 of 2'),
      children: [
        TSteps(n: 1, total: 2),
        TTitle('Which describes you?'),
        TBody('As told by a clinician.', tone: TTextTone.muted),
        TRadioList(fieldKey: 'st_q1.value', items: [TRadioItem('Type 2 diabetes'), TRadioItem('Prediabetes'), TRadioItem('Type 1 diabetes', sub: 'Logging only; follow your care team for insulin'), TRadioItem('Gestational diabetes', sub: 'Education only; talk with your care team'), TRadioItem('Not diagnosed: learn')], selected: 0),
        TSegmented(fieldKey: 'st_q1.how_do_you_check', options: ['Meter', 'CGM', 'Lab only'], selected: 'Meter', label: 'How do you check?'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.push(context, Routes.stRange), arrow: true),
      ],
    );
  }
}
