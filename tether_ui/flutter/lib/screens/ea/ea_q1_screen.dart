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
    return TScreen(
      header: THeader(title: 'Optional check', pill: '1 of 4'),
      children: [
        TSteps(n: 1, total: 4),
        TBody('Over the last 2 weeks, how often have you been bothered by…', tone: TTextTone.small),
        TTitle('Little interest or pleasure in doing things?'),
        TRadioList(fieldKey: 'ea_q1.value', items: [TRadioItem('Not at all'), TRadioItem('Several days'), TRadioItem('More than half the days'), TRadioItem('Nearly every day')], selected: 1),
        TBody('PHQ-2 / GAD-2 · validated questions · skippable', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.push(context, Routes.eaResult), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Skip the check', onPressed: () => TNav.push(context, Routes.eaPlan), variant: TButtonVariant.secondary),
      ],
    );
  }
}
