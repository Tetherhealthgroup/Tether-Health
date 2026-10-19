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
    return TScreen(
      header: THeader(title: 'Enter a value'),
      children: [
        TTitle('Add a health value'),
        TField(fieldKey: 'records_manual_error.test', label: 'Test', placeholder: 'A1C', kind: TFieldKind.select),
        TField(fieldKey: 'records_manual_error.value', label: 'Value', unit: '%', error: 'A1C is usually between 4% and 15%. Did you mean 7.4?', placeholder: '74', kind: TFieldKind.number),
        TField(fieldKey: 'records_manual_error.date', label: 'Date', placeholder: 'Oct 1, 2026', kind: TFieldKind.date),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'POST /v1/records/manual', then: () => TNav.branch(context, 'Validation', <String, VoidCallback>{'Valid': () => TNav.toast(context, 'Saved · shared with Steady', then: () => TNav.popTo(context, Routes.recordsHub)), 'Outside expected range': () => TNav.toast(context, 'Still outside the expected range')}, decide: 'rec.manual')), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Ask my care team instead', onTap: () => TNav.push(context, Routes.supportMessageCare)),
      ],
    );
  }
}
