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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.beQ2HeaderTitle, pill: s.beQ2HeaderPill),
      children: [
        TSteps(n: 2, total: 2),
        TTitle(s.beQ2BodyN1Text),
        TChips(fieldKey: 'be_q2.value', options: ['Breast', 'Ovarian', 'Colorectal', 'Prostate', 'Pancreatic', 'Melanoma', 'None', 'Not sure'], labels: [s.beQ2BodyN2OptionsN0, s.beQ2BodyN2OptionsN1, s.beQ2BodyN2OptionsN2, s.beQ2BodyN2OptionsN3, s.beQ2BodyN2OptionsN4, s.beQ2BodyN2OptionsN5, s.beQ2BodyN2OptionsN6, s.beQ2BodyN2OptionsN7], selected: ['Breast'], bind: 'be.profile.family_cancers', bindClass: TBindClass.plan),
        TField(fieldKey: 'be_q2.relative_s_age_at_diagnosis_if_k', label: s.beQ2BodyN3Label, placeholder: '44', kind: TFieldKind.number),
        TCard(variant: TCardVariant.mint, text: s.beQ2BodyN4Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.beQ2FooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/be/profile', screenId: 'be_q2', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.beHome))), arrow: true),
      ],
    );
  }
}
