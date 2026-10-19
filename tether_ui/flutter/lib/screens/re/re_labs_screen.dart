// GENERATED from spec/screens/re_labs.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Add labs  ·  route `/p/re/labs`  ·  flow `re`  ·  kind `screen`
/// Default state · program re · phase milestone
/// 
///
/// Actions (generated from spec/screens/re_labs.json):
///   • Back → back
///   • Import from my health record → push → records_add
///   • Save results → POST /v1/program-data/re/labs then toast “Saved” then replace → re_history
/// API: —
class ReLabsScreen extends StatelessWidget {
  const ReLabsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Add lab results', pill: 'Lab'),
      children: [
        TField(fieldKey: 're_labs.egfr', label: 'eGFR', unit: 'mL/min/1.73m²', placeholder: '58', kind: TFieldKind.number),
        TField(fieldKey: 're_labs.urine_acr', label: 'Urine ACR', unit: 'mg/g', placeholder: '42', kind: TFieldKind.number),
        TField(fieldKey: 're_labs.alt_liver', label: 'ALT (liver)', unit: 'U/L', placeholder: 'Optional', kind: TFieldKind.number),
        TField(fieldKey: 're_labs.lab_date', label: 'Lab date', placeholder: 'Oct 3, 2026', kind: TFieldKind.date),
        TBody('Copy numbers exactly from your report. Renew shows trends; your clinician explains them.', tone: TTextTone.small),
        TLink(key: const ValueKey('a:body[5]'), label: 'Import from my health record', onTap: () => TNav.push(context, Routes.recordsAdd)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save results', onPressed: () => TNav.submit(context, 'POST /v1/program-data/re/labs', screenId: 're_labs', then: () => TNav.toast(context, 'Saved', then: () => TNav.replace(context, Routes.reHistory))), arrow: true),
      ],
    );
  }
}
