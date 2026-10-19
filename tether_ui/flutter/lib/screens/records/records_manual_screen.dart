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
    return TScreen(
      header: THeader(title: 'Enter a value'),
      children: [
        TTitle('Add a health value'),
        TChips(fieldKey: 'records_manual.type', options: ['Blood pressure', 'Glucose', 'Lab result', 'Vaccine', 'Medication', 'Condition'], selected: ['Lab result'], multi: false, label: 'Type'),
        TField(fieldKey: 'records_manual.test', label: 'Test', placeholder: 'A1C', kind: TFieldKind.select),
        TField(fieldKey: 'records_manual.value', label: 'Value', unit: '%', placeholder: '7.4', kind: TFieldKind.number),
        TField(fieldKey: 'records_manual.date', label: 'Date', placeholder: 'Oct 1, 2026', kind: TFieldKind.date),
        TBody('Checked against plausible ranges and your connected records. Manual values are labelled “Entered by you”.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'POST /v1/records/manual', then: () => TNav.branch(context, 'Validation', <String, VoidCallback>{'Valid': () => TNav.toast(context, 'Saved · shared with Steady', then: () => TNav.popTo(context, Routes.recordsHub)), 'Outside expected range': () => TNav.replace(context, Routes.recordsManualError), 'Matches an imported value': () => TNav.toast(context, 'Already in your records from Epic. Not added twice.', then: () => TNav.back(context))}, decide: 'rec.manual')), arrow: true),
      ],
    );
  }
}
