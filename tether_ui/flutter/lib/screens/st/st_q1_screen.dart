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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.stQ1HeaderTitle, pill: s.stQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 2),
        TTitle(s.stQ1BodyN1Text),
        TBody(s.stQ1BodyN2Text, tone: TTextTone.muted),
        TRadioList(fieldKey: 'st_q1.value', items: [TRadioItem(s.stQ1BodyN3ItemsN0Label, value: 'Type 2 diabetes'), TRadioItem(s.stQ1BodyN3ItemsN1Label, value: 'Prediabetes'), TRadioItem(s.stQ1BodyN3ItemsN2Label, value: 'Type 1 diabetes', sub: s.stQ1BodyN3ItemsN2Sub), TRadioItem(s.stQ1BodyN3ItemsN3Label, value: 'Gestational diabetes', sub: s.stQ1BodyN3ItemsN3Sub), TRadioItem(s.stQ1BodyN3ItemsN4Label, value: 'Not diagnosed: learn')], selected: 0),
        TSegmented(fieldKey: 'st_q1.how_do_you_check', options: ['Meter', 'CGM', 'Lab only'], labels: [s.stQ1BodyN4OptionsN0, s.stQ1BodyN4OptionsN1, s.stQ1BodyN4OptionsN2], selected: 'Meter', label: s.stQ1BodyN4Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.stQ1FooterN0Label, onPressed: () => TNav.push(context, Routes.stRange), arrow: true),
      ],
    );
  }
}
