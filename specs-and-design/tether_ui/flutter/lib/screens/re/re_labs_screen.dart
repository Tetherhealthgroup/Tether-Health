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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.reLabsHeaderTitle, pill: s.reLabsHeaderPill),
      children: [
        TField(fieldKey: 're_labs.egfr', label: s.reLabsBodyN0Label, unit: 'mL/min/1.73m²', placeholder: '58', kind: TFieldKind.number),
        TField(fieldKey: 're_labs.urine_acr', label: s.reLabsBodyN1Label, unit: 'mg/g', placeholder: '42', kind: TFieldKind.number),
        TField(fieldKey: 're_labs.alt_liver', label: s.reLabsBodyN2Label, unit: 'U/L', placeholder: s.reLabsBodyN2Placeholder, kind: TFieldKind.number),
        TField(fieldKey: 're_labs.lab_date', label: s.reLabsBodyN3Label, placeholder: s.reLabsBodyN3Placeholder, kind: TFieldKind.date),
        TBody(s.reLabsBodyN4Text, tone: TTextTone.small),
        TLink(key: const ValueKey('a:body[5]'), label: s.reLabsBodyN5Label, onTap: () => TNav.push(context, Routes.recordsAdd)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.reLabsFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/re/labs', screenId: 're_labs', then: () => TNav.toast(context, s.reLabsFooterN0ActionThenValue, then: () => TNav.replace(context, Routes.reHistory))), arrow: true),
      ],
    );
  }
}
