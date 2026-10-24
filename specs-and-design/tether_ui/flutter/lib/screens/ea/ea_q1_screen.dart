// GENERATED from spec/screens/ea_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Optional screener  ·  route `/p/ea/onboarding/1`  ·  flow `ea`  ·  kind `screen`
/// Default state · program ea · phase onboarding
/// 4 questions in production (PHQ-2 + GAD-2); one shown.
///
/// Actions (generated from spec/screens/ea_q1.json):
///   • Back → back
///   • Next → push → ea_result
///   • Skip the check → push → ea_plan
/// API: —
class EaQ1Screen extends StatelessWidget {
  const EaQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.eaQ1HeaderTitle, pill: s.eaQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 4),
        TBody(s.eaQ1BodyN1Text, tone: TTextTone.small),
        TTitle(s.eaQ1BodyN2Text),
        TRadioList(fieldKey: 'ea_q1.value', items: [TRadioItem(s.eaQ1BodyN3ItemsN0Label, value: 'Not at all'), TRadioItem(s.eaQ1BodyN3ItemsN1Label, value: 'Several days'), TRadioItem(s.eaQ1BodyN3ItemsN2Label, value: 'More than half the days'), TRadioItem(s.eaQ1BodyN3ItemsN3Label, value: 'Nearly every day')], selected: 1),
        TBody(s.eaQ1BodyN4Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.eaQ1FooterN0Label, onPressed: () => TNav.push(context, Routes.eaResult), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.eaQ1FooterN1Label, onPressed: () => TNav.push(context, Routes.eaPlan), variant: TButtonVariant.secondary),
      ],
    );
  }
}
