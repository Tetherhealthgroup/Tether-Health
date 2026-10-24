// GENERATED from spec/screens/ck_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// About you  ·  route `/p/ck/onboarding/1`  ·  flow `ck`  ·  kind `screen`
/// Default state · program ck · phase onboarding
/// 
///
/// Actions (generated from spec/screens/ck_q1.json):
///   • Back → back
///   • Import vaccination history → push → records_add
///   • Build my list → PUT /v1/program-data/ck/profile then replace → ck_list (onboarding: ob_setup)
/// API: —
class CkQ1Screen extends StatelessWidget {
  const CkQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.ckQ1HeaderTitle, pill: s.ckQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 1),
        TTitle(s.ckQ1BodyN1Text),
        TField(fieldKey: 'ck_q1.age', label: s.ckQ1BodyN2Label, placeholder: '52', kind: TFieldKind.number),
        TSegmented(fieldKey: 'ck_q1.sex_assigned_at_birth', options: ['Female', 'Male', 'Intersex', 'Skip'], labels: [s.ckQ1BodyN3OptionsN0, s.ckQ1BodyN3OptionsN1, s.ckQ1BodyN3OptionsN2, s.ckQ1BodyN3OptionsN3], selected: 'Female', label: s.ckQ1BodyN3Label, bind: 'ck.profile.sex_assigned_at_birth', bindClass: TBindClass.plan),
        TChips(fieldKey: 'ck_q1.any_of_these', options: ['Smoke or used to', 'Diabetes', 'Family history of cancer', 'Pregnant', 'None'], labels: [s.ckQ1BodyN4OptionsN0, s.ckQ1BodyN4OptionsN1, s.ckQ1BodyN4OptionsN2, s.ckQ1BodyN4OptionsN3, s.ckQ1BodyN4OptionsN4], selected: ['Smoke or used to'], label: s.ckQ1BodyN4Label, bind: 'ck.profile.any_of_these', bindClass: TBindClass.plan),
        TBody(s.ckQ1BodyN5Text, tone: TTextTone.small),
        TLink(key: const ValueKey('a:body[6]'), label: s.ckQ1BodyN6Label, onTap: () => TNav.push(context, Routes.recordsAdd)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.ckQ1FooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/ck/profile', screenId: 'ck_q1', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.ckList))), arrow: true),
      ],
    );
  }
}
