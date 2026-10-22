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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sdPlanHeaderTitle, pill: s.sdPlanHeaderPill),
      children: [
        TTitle(s.sdPlanBodyN0Text),
        TKeyValue(rows: [(s.sdPlanBodyN1RowsN0N0, s.sdPlanBodyN1RowsN0N1), (s.sdPlanBodyN1RowsN1N0, s.sdPlanBodyN1RowsN1N1), (s.sdPlanBodyN1RowsN2N0, s.sdPlanBodyN1RowsN2N1)]),
        TCard(children: [TChecklist(items: [TCheckItem(s.sdPlanBodyN2ChildrenN0ItemsN0Label, value: 'Do sessions near a sturdy chair', done: true), TCheckItem(s.sdPlanBodyN2ChildrenN0ItemsN1Label, value: 'Tell my caregiver when I finish')])]),
        TBody(s.sdPlanBodyN3Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sdPlanFooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/sd/plan', screenId: 'sd_plan', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.sdHome))), arrow: true),
      ],
    );
  }
}
