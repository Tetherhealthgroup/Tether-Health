// GENERATED from spec/screens/be_q2.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Family history  ·  route `/p/be/onboarding/2`  ·  flow `be`  ·  kind `screen`
/// Default state · program be · phase onboarding
/// 
///
/// Actions (generated from spec/screens/be_q2.json):
///   • Back → back
///   • See my plan → PUT /v1/program-data/be/profile then replace → be_home (onboarding: ob_setup)
/// API: —
class BeQ2Screen extends StatelessWidget {
  const BeQ2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Family history', pill: '2 of 2'),
      children: [
        TSteps(n: 2, total: 2),
        TTitle('Has a close relative had cancer?'),
        TChips(fieldKey: 'be_q2.value', options: ['Breast', 'Ovarian', 'Colorectal', 'Prostate', 'Pancreatic', 'Melanoma', 'None', 'Not sure'], selected: ['Breast']),
        TField(fieldKey: 'be_q2.relative_s_age_at_diagnosis_if_k', label: 'Relative’s age at diagnosis (if known)', placeholder: '44', kind: TFieldKind.number),
        TCard(variant: TCardVariant.mint, text: 'A relative diagnosed before 50 may mean earlier screening or genetic counseling. We’ll add this to your visit list.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'See my plan', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/be/profile', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.beHome))), arrow: true),
      ],
    );
  }
}
