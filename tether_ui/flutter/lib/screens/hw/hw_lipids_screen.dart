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
    return TScreen(
      header: THeader(title: 'Cholesterol panel', pill: 'Lab'),
      children: [
        TTitle('Add your lab results'),
        TBody('Copy from your lab report. Units: mg/dL.', tone: TTextTone.muted),
        TFieldRow(children: [TField(fieldKey: 'hw_lipids.total', label: 'Total', unit: 'mg/dL', placeholder: '212', kind: TFieldKind.number), TField(fieldKey: 'hw_lipids.ldl', label: 'LDL', unit: 'mg/dL', placeholder: '138', kind: TFieldKind.number)]),
        TFieldRow(children: [TField(fieldKey: 'hw_lipids.hdl', label: 'HDL', unit: 'mg/dL', placeholder: '46', kind: TFieldKind.number), TField(fieldKey: 'hw_lipids.triglycerides', label: 'Triglycerides', unit: 'mg/dL', placeholder: 'Optional', kind: TFieldKind.number)]),
        TField(fieldKey: 'hw_lipids.lab_date', label: 'Lab date', placeholder: 'Sep 30, 2026', kind: TFieldKind.date),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save panel', onPressed: () => TNav.submit(context, 'POST /v1/program-data/hw/lipids', screenId: 'hw_lipids', then: () => TNav.toast(context, 'Panel saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
