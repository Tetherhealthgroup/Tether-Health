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
    return TScreen(
      header: THeader(title: 'Your action plan', pill: '2 of 2'),
      children: [
        TSteps(n: 2, total: 2),
        TTitle('Copy your plan from your clinician.'),
        TBody('ClearAir never creates or changes zones.', tone: TTextTone.muted),
        TCard(eyebrow: 'Green zone', children: [TField(fieldKey: 'ca_plan.green_from', label: 'Peak flow from', unit: 'L/min', placeholder: '400', kind: TFieldKind.number), TField(fieldKey: 'ca_plan.daily_medicine', label: 'Daily medicine', placeholder: 'Controller inhaler · 2 puffs AM/PM')]),
        TCard(eyebrow: 'Yellow zone', children: [TField(fieldKey: 'ca_plan.peak_flow', label: 'Peak flow', unit: 'L/min', placeholder: '200–399')]),
        TCard(eyebrow: 'Red zone', children: [TField(fieldKey: 'ca_plan.red_below', label: 'Below', unit: 'L/min', placeholder: '200', kind: TFieldKind.number)]),
        TButton(key: const ValueKey('a:body[6]'), label: 'Add a photo of my plan', onPressed: () => TNav.toast(context, 'Camera opened'), variant: TButtonVariant.secondary),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save plan', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/ca/plan', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.caHome))), arrow: true),
      ],
    );
  }
}
