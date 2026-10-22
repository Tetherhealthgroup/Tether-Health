// GENERATED from spec/screens/ca_plan.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Enter action plan  ·  route `/p/ca/plan`  ·  flow `ca`  ·  kind `screen`
/// Default state · program ca · phase plan
/// 
///
/// Actions (generated from spec/screens/ca_plan.json):
///   • Back → back
///   • Add a photo of my plan → toast “Camera opened”
///   • Save plan → PUT /v1/program-data/ca/plan then replace → ca_home (onboarding: ob_setup)
/// API: —
class CaPlanScreen extends StatelessWidget {
  const CaPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.caPlanHeaderTitle, pill: s.caPlanHeaderPill),
      children: [
        TSteps(n: 2, total: 2),
        TTitle(s.caPlanBodyN1Text),
        TBody(s.caPlanBodyN2Text, tone: TTextTone.muted),
        TCard(eyebrow: s.caPlanBodyN3Eyebrow, children: [TField(fieldKey: 'ca_plan.green_from', label: s.caPlanBodyN3ChildrenN0Label, unit: 'L/min', placeholder: '400', kind: TFieldKind.number), TField(fieldKey: 'ca_plan.daily_medicine', label: s.caPlanBodyN3ChildrenN1Label, placeholder: s.caPlanBodyN3ChildrenN1Placeholder)]),
        TCard(eyebrow: s.caPlanBodyN4Eyebrow, children: [TField(fieldKey: 'ca_plan.peak_flow', label: s.caPlanBodyN4ChildrenN0Label, unit: 'L/min', placeholder: '200–399')]),
        TCard(eyebrow: s.caPlanBodyN5Eyebrow, children: [TField(fieldKey: 'ca_plan.red_below', label: s.caPlanBodyN5ChildrenN0Label, unit: 'L/min', placeholder: '200', kind: TFieldKind.number)]),
        TButton(key: const ValueKey('a:body[6]'), label: s.caPlanBodyN6Label, onPressed: () => TNav.toast(context, s.caPlanBodyN6ActionValue), variant: TButtonVariant.secondary),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.caPlanFooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/ca/plan', screenId: 'ca_plan', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.caHome))), arrow: true),
      ],
    );
  }
}
