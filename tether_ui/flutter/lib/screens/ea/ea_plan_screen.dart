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
    return TScreen(
      header: THeader(title: 'Safety plan', pill: 'Private'),
      children: [
        TTitle('Make a plan for hard moments'),
        TBody('Based on the Stanley-Brown safety plan. Only you can see this.', tone: TTextTone.small),
        TField(fieldKey: 'ea_plan.my_warning_signs', label: 'My warning signs', placeholder: 'Not sleeping, pulling away from friends', kind: TFieldKind.multiline),
        TField(fieldKey: 'ea_plan.things_that_help_me', label: 'Things that help me', placeholder: 'Walk the dog, shower, music'),
        TField(fieldKey: 'ea_plan.people_i_can_reach', label: 'People I can reach', placeholder: 'Sam · (555) 010-3311'),
        TKeyValue(rows: [('Crisis line', '988 · call or text'), ('Emergency', '911')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save plan', onPressed: () => TNav.submit(context, 'PUT device:encrypted/ea/safety-plan', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.eaHome))), arrow: true),
      ],
    );
  }
}
