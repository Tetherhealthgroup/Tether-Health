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
    return TScreen(
      header: THeader(title: 'About you', pill: '1 of 1'),
      children: [
        TSteps(n: 1, total: 1),
        TTitle('A few details to personalize'),
        TField(fieldKey: 'ck_q1.age', label: 'Age', value: '52', kind: TFieldKind.number),
        TSegmented(fieldKey: 'ck_q1.sex_assigned_at_birth', options: ['Female', 'Male', 'Intersex', 'Skip'], selected: 'Female', label: 'Sex assigned at birth'),
        TChips(fieldKey: 'ck_q1.any_of_these', options: ['Smoke or used to', 'Diabetes', 'Family history of cancer', 'Pregnant', 'None'], selected: ['Smoke or used to'], label: 'Any of these?'),
        TBody('Used only to build your list. Change anytime.', tone: TTextTone.small),
        TLink(key: const ValueKey('a:body[6]'), label: 'Import vaccination history', onTap: () => TNav.push(context, Routes.recordsAdd)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Build my list', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/ck/profile', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.ckList))), arrow: true),
      ],
    );
  }
}
