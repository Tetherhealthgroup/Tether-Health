// GENERATED from spec/screens/records_manual.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Enter a value  ·  route `/records/manual`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_manual.json):
///   • Back → back
///   • Save → POST /v1/records/manual then decide rec.manual: Validation → Valid: toast “Saved · shared with Steady” then popto → records_hub | Outside expected range: replace → records_manual_error | Matches an imported value: toast “Already in your records from Epic. Not added twice.” then back
/// API: —
class RecordsManualScreen extends StatelessWidget {
  const RecordsManualScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsManualHeaderTitle),
      children: [
        TTitle(s.recordsManualBodyN0Text),
        TChips(fieldKey: 'records_manual.type', options: ['Blood pressure', 'Glucose', 'Lab result', 'Vaccine', 'Medication', 'Condition'], labels: [s.recordsManualBodyN1OptionsN0, s.recordsManualBodyN1OptionsN1, s.recordsManualBodyN1OptionsN2, s.recordsManualBodyN1OptionsN3, s.recordsManualBodyN1OptionsN4, s.recordsManualBodyN1OptionsN5], selected: ['Lab result'], multi: false, label: s.recordsManualBodyN1Label),
        TField(fieldKey: 'records_manual.test', label: s.recordsManualBodyN2Label, placeholder: s.recordsManualBodyN2Placeholder, kind: TFieldKind.select),
        TField(fieldKey: 'records_manual.value', label: s.recordsManualBodyN3Label, unit: '%', placeholder: '7.4', kind: TFieldKind.number),
        TField(fieldKey: 'records_manual.date', label: s.recordsManualBodyN4Label, placeholder: s.recordsManualBodyN4Placeholder, kind: TFieldKind.date),
        TBody(s.recordsManualBodyN5Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsManualFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/records/manual', screenId: 'records_manual', then: () => TNav.branch(context, 'Validation', <String, VoidCallback>{'Valid': () => TNav.toast(context, s.recordsManualFooterN0ActionThenCasesN0ActionValue, then: () => TNav.popTo(context, Routes.recordsHub)), 'Outside expected range': () => TNav.replace(context, Routes.recordsManualError), 'Matches an imported value': () => TNav.toast(context, s.recordsManualFooterN0ActionThenCasesN2ActionValue, then: () => TNav.back(context))}, decide: 'rec.manual')), arrow: true),
      ],
    );
  }
}
