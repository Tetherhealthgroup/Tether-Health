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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.hwTargetsHeaderTitle, pill: s.hwTargetsHeaderPill),
      children: [
        TSteps(n: 2, total: 2),
        TTitle(s.hwTargetsBodyN1Text),
        TFieldRow(children: [TField(fieldKey: 'hw_targets.top_below', label: s.hwTargetsBodyN2FieldsN0Label, unit: 'mmHg', placeholder: '130', kind: TFieldKind.number), TField(fieldKey: 'hw_targets.bottom_below', label: s.hwTargetsBodyN2FieldsN1Label, unit: 'mmHg', placeholder: '80', kind: TFieldKind.number)]),
        TRadioList(fieldKey: 'hw_targets.value', items: [TRadioItem(s.hwTargetsBodyN3ItemsN0Label, value: 'I don’t have a target yet', sub: s.hwTargetsBodyN3ItemsN0Sub)], selected: -1, bind: 'hw.targets.no_target_yet', bindClass: TBindClass.plan),
        TChips(fieldKey: 'hw_targets.when_should_we_remind_you', options: ['Morning', 'Evening', 'Both'], labels: [s.hwTargetsBodyN4OptionsN0, s.hwTargetsBodyN4OptionsN1, s.hwTargetsBodyN4OptionsN2], selected: ['Both'], multi: false, label: s.hwTargetsBodyN4Label, bind: 'hw.targets.reminder_time', bindClass: TBindClass.plan),
        TBody(s.hwTargetsBodyN5Text, tone: TTextTone.small),
        TLink(key: const ValueKey('a:body[6]'), label: s.hwTargetsBodyN6Label, onTap: () => TNav.push(context, Routes.recordsAdd)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.hwTargetsFooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/hw/targets', screenId: 'hw_targets', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.hwHome))), arrow: true),
      ],
    );
  }
}
