// GENERATED from spec/screens/records_manual_error.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Enter a value · out of range  ·  route `/records/manual?state=error`  ·  flow `records`  ·  kind `screen`
/// State: error of records_manual · phase resources
/// 
///
/// Actions (generated from spec/screens/records_manual_error.json):
///   • Back → back
///   • Save → POST /v1/records/manual then decide rec.manual: Validation → Valid: toast “Saved · shared with Steady” then popto → records_hub | Outside expected range: toast “Still outside the expected range”
///   • Ask my care team instead → push → support_message_care
/// API: —
class RecordsManualErrorScreen extends StatelessWidget {
  const RecordsManualErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsManualErrorHeaderTitle),
      children: [
        TTitle(s.recordsManualErrorBodyN0Text),
        TField(fieldKey: 'records_manual_error.test', label: s.recordsManualErrorBodyN1Label, placeholder: s.recordsManualErrorBodyN1Placeholder, kind: TFieldKind.select),
        TField(fieldKey: 'records_manual_error.value', label: s.recordsManualErrorBodyN2Label, unit: '%', error: s.recordsManualErrorBodyN2Error, placeholder: '74', kind: TFieldKind.number),
        TField(fieldKey: 'records_manual_error.date', label: s.recordsManualErrorBodyN3Label, placeholder: s.recordsManualErrorBodyN3Placeholder, kind: TFieldKind.date),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsManualErrorFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/records/manual', screenId: 'records_manual_error', then: () => TNav.branch(context, 'Validation', <String, VoidCallback>{'Valid': () => TNav.toast(context, s.recordsManualErrorFooterN0ActionThenCasesN0ActionValue, then: () => TNav.popTo(context, Routes.recordsHub)), 'Outside expected range': () => TNav.toast(context, s.recordsManualErrorFooterN0ActionThenCasesN1ActionValue)}, decide: 'rec.manual')), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.recordsManualErrorFooterN1Label, onTap: () => TNav.push(context, Routes.supportMessageCare)),
      ],
    );
  }
}
