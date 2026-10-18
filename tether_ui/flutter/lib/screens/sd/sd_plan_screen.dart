// GENERATED from spec/screens/sd_plan.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Movement plan  ·  route `/p/sd/plan`  ·  flow `sd`  ·  kind `screen`
/// Default state · program sd · phase plan
/// 
///
/// Actions (generated from spec/screens/sd_plan.json):
///   • Back → back
///   • Start plan → PUT /v1/program-data/sd/plan then replace → sd_home (onboarding: ob_setup)
/// API: —
class SdPlanScreen extends StatelessWidget {
  const SdPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your movement plan', pill: 'Plan'),
      children: [
        TTitle('Three short sessions a week'),
        TKeyValue(rows: [('Mon', 'Balance · 8 min'), ('Wed', 'Strength (chair) · 10 min'), ('Fri', 'Walk + balance · 12 min')]),
        TCard(children: [TChecklist(items: [TCheckItem('Do sessions near a sturdy chair', done: true), TCheckItem('Tell my caregiver when I finish')])]),
        TBody('Check with your clinician before starting a new exercise program.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Start plan', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/sd/plan', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.sdHome))), arrow: true),
      ],
    );
  }
}
