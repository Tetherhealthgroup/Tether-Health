// GENERATED from spec/screens/bf_meds_edit.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Edit recorded plan  ·  route `/p/bf/meds/edit`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase resources
/// 
///
/// Actions (generated from spec/screens/bf_meds_edit.json):
///   • Back → back
///   • Save plan → PUT /v1/program-data/bf/meds then toast “Plan saved” then back
/// API: —
class BfMedsEditScreen extends StatelessWidget {
  const BfMedsEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Recorded plan'),
      children: [
        TTitle('Record the plan from your clinician'),
        TField(fieldKey: 'bf_meds_edit.medicine', label: 'Medicine', value: 'Nicotine patch', kind: TFieldKind.select),
        TField(fieldKey: 'bf_meds_edit.strength', label: 'Strength', value: '21 mg / 24 h'),
        TField(fieldKey: 'bf_meds_edit.when', label: 'When', value: 'Every morning', kind: TFieldKind.select),
        TToggleRow(fieldKey: 'bf_meds_edit.private_reminder', label: 'Private reminder', sub: 'Lock screen hides the medicine name', value: true),
        TBody('You’re recording, not changing, your plan. Ask your clinician about any change.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save plan', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/bf/meds', then: () => TNav.toast(context, 'Plan saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
