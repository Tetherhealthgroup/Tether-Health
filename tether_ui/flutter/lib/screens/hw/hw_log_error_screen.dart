// GENERATED from spec/screens/hw_log_error.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Log BP · validation  ·  route `/p/hw/log/2?state=error`  ·  flow `hw`  ·  kind `screen`
/// State: error of hw_log2 · program hw · phase daily
/// 
///
/// Actions (generated from spec/screens/hw_log_error.json):
///   • Back → back
///   • Save readings → disabled
///   • Edit reading → replace → hw_log2
/// API: —
class HwLogErrorScreen extends StatelessWidget {
  const HwLogErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Log blood pressure', pill: 'Check'),
      children: [
        TTitle('Let’s double-check that.'),
        TFieldRow(children: [TField(fieldKey: 'hw_log_error.top_systolic', label: 'Top (systolic)', unit: 'mmHg', placeholder: '128', kind: TFieldKind.number), TField(fieldKey: 'hw_log_error.bottom_diastolic', label: 'Bottom (diastolic)', unit: 'mmHg', error: 'Too high for the bottom number. Did you mean 81?', placeholder: '310', kind: TFieldKind.number)]),
        TBody('Valid range: top 70–250, bottom 40–150, bottom lower than top.', tone: TTextTone.small),
      ],
      footer: [
        TButton(label: 'Save readings', onPressed: null, arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Edit reading', onTap: () => TNav.replace(context, Routes.hwLog2)),
      ],
    );
  }
}
