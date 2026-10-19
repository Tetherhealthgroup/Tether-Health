// GENERATED from spec/screens/hw_log2.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Log BP · reading 2  ·  route `/p/hw/log/2`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase daily
/// 
///
/// Actions (generated from spec/screens/hw_log2.json):
///   • Back → back
///   • Save readings → POST /v1/program-data/hw/readings then decide hw.bp: Validated average → Valid · below crisis range: replace → hw_result | Invalid value: replace → hw_log_error | ≥180 top or ≥120 bottom: replace → hw_crisis
/// API: —
class HwLog2Screen extends StatelessWidget {
  const HwLog2Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Log blood pressure', pill: '2 of 2'),
      children: [
        TTitle('Second reading'),
        TBody('Same arm, 1 minute later.', tone: TTextTone.muted),
        TFieldRow(children: [TField(fieldKey: 'hw_log2.systolic', label: 'Top (systolic)', unit: 'mmHg', placeholder: '132', kind: TFieldKind.number), TField(fieldKey: 'hw_log2.diastolic', label: 'Bottom (diastolic)', unit: 'mmHg', placeholder: '84', kind: TFieldKind.number)]),
        TField(fieldKey: 'hw_log2.pulse_optional', label: 'Pulse (optional)', unit: 'bpm', placeholder: '70', kind: TFieldKind.number),
        TKeyValue(rows: [('Reading 1', '138/86'), ('Average so far', '135/85')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save readings', onPressed: () => TNav.submit(context, 'POST /v1/program-data/hw/readings', screenId: 'hw_log2', then: () => TNav.branch(context, 'Validated average', <String, VoidCallback>{'Valid · below crisis range': () => TNav.replace(context, Routes.hwResult), 'Invalid value': () => TNav.replace(context, Routes.hwLogError), '≥180 top or ≥120 bottom': () => TNav.replace(context, Routes.hwCrisis)}, decide: 'hw.bp'), safety: TSafetyRoutes('hw.bp', <String, VoidCallback>{'≥180 top or ≥120 bottom': () => TNav.replace(context, Routes.hwCrisis)})), arrow: true),
      ],
    );
  }
}
