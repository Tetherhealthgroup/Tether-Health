// GENERATED from spec/screens/hw_targets.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Clinician targets  ·  route `/p/hw/plan/targets`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase plan
/// 
///
/// Actions (generated from spec/screens/hw_targets.json):
///   • Back → back
///   • Import from my health record → push → records_add
///   • Save targets → PUT /v1/program-data/hw/targets then replace → hw_home (onboarding: ob_setup)
/// API: —
class HwTargetsScreen extends StatelessWidget {
  const HwTargetsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your targets', pill: '2 of 2'),
      children: [
        TSteps(n: 2, total: 2),
        TTitle('What target did your clinician give you?'),
        TFieldRow(children: [TField(fieldKey: 'hw_targets.top_below', label: 'Top below', value: '130', unit: 'mmHg', kind: TFieldKind.number), TField(fieldKey: 'hw_targets.bottom_below', label: 'Bottom below', value: '80', unit: 'mmHg', kind: TFieldKind.number)]),
        TRadioList(fieldKey: 'hw_targets.value', items: [TRadioItem('I don’t have a target yet', sub: 'Readings show without a target line')], selected: -1),
        TChips(fieldKey: 'hw_targets.when_should_we_remind_you', options: ['Morning', 'Evening', 'Both'], selected: ['Both'], multi: false, label: 'When should we remind you?'),
        TBody('Heartwise never sets or grades targets.', tone: TTextTone.small),
        TLink(key: const ValueKey('a:body[6]'), label: 'Import from my health record', onTap: () => TNav.push(context, Routes.recordsAdd)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save targets', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/hw/targets', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.hwHome))), arrow: true),
      ],
    );
  }
}
