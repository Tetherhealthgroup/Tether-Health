// GENERATED from spec/screens/ea_plan.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Safety plan  ·  route `/p/ea/plan`  ·  flow `ea`  ·  kind `screen`
/// Default state · program ea · phase plan
/// Stored encrypted on the device only.
///
/// Actions (generated from spec/screens/ea_plan.json):
///   • Back → back
///   • Save plan → PUT device:encrypted/ea/safety-plan then replace → ea_home (onboarding: ob_setup)
/// API: —
class EaPlanScreen extends StatelessWidget {
  const EaPlanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.eaPlanHeaderTitle, pill: s.eaPlanHeaderPill),
      children: [
        TTitle(s.eaPlanBodyN0Text),
        TBody(s.eaPlanBodyN1Text, tone: TTextTone.small),
        TField(fieldKey: 'ea_plan.my_warning_signs', label: s.eaPlanBodyN2Label, placeholder: s.eaPlanBodyN2Placeholder, kind: TFieldKind.multiline),
        TField(fieldKey: 'ea_plan.things_that_help_me', label: s.eaPlanBodyN3Label, placeholder: s.eaPlanBodyN3Placeholder),
        TField(fieldKey: 'ea_plan.people_i_can_reach', label: s.eaPlanBodyN4Label, placeholder: s.eaPlanBodyN4Placeholder),
        TKeyValue(rows: [(s.eaPlanBodyN5RowsN0N0, s.eaPlanBodyN5RowsN0N1), (s.eaPlanBodyN5RowsN1N0, '911')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.eaPlanFooterN0Label, onPressed: () => TNav.submit(context, 'PUT device:encrypted/ea/safety-plan', screenId: 'ea_plan', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.eaHome))), arrow: true),
      ],
    );
  }
}
