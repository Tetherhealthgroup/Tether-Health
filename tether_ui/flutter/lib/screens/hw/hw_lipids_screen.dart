// GENERATED from spec/screens/hw_lipids.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Cholesterol panel  ·  route `/p/hw/lipids`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase milestone
/// 
///
/// Actions (generated from spec/screens/hw_lipids.json):
///   • Back → back
///   • Save panel → POST /v1/program-data/hw/lipids then toast “Panel saved” then back
/// API: —
class HwLipidsScreen extends StatelessWidget {
  const HwLipidsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.hwLipidsHeaderTitle, pill: s.hwLipidsHeaderPill),
      children: [
        TTitle(s.hwLipidsBodyN0Text),
        TBody(s.hwLipidsBodyN1Text, tone: TTextTone.muted),
        TFieldRow(children: [TField(fieldKey: 'hw_lipids.total', label: s.hwLipidsBodyN2FieldsN0Label, unit: 'mg/dL', placeholder: '212', kind: TFieldKind.number), TField(fieldKey: 'hw_lipids.ldl', label: s.hwLipidsBodyN2FieldsN1Label, unit: 'mg/dL', placeholder: '138', kind: TFieldKind.number)]),
        TFieldRow(children: [TField(fieldKey: 'hw_lipids.hdl', label: s.hwLipidsBodyN3FieldsN0Label, unit: 'mg/dL', placeholder: '46', kind: TFieldKind.number), TField(fieldKey: 'hw_lipids.triglycerides', label: s.hwLipidsBodyN3FieldsN1Label, unit: 'mg/dL', placeholder: s.hwLipidsBodyN3FieldsN1Placeholder, kind: TFieldKind.number)]),
        TField(fieldKey: 'hw_lipids.lab_date', label: s.hwLipidsBodyN4Label, placeholder: s.hwLipidsBodyN4Placeholder, kind: TFieldKind.date),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.hwLipidsFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/hw/lipids', screenId: 'hw_lipids', then: () => TNav.toast(context, s.hwLipidsFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
