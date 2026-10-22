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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.hwLogErrorHeaderTitle, pill: s.hwLogErrorHeaderPill),
      children: [
        TTitle(s.hwLogErrorBodyN0Text),
        TFieldRow(children: [TField(fieldKey: 'hw_log_error.top_systolic', label: s.hwLogErrorBodyN1FieldsN0Label, unit: 'mmHg', placeholder: '128', kind: TFieldKind.number), TField(fieldKey: 'hw_log_error.bottom_diastolic', label: s.hwLogErrorBodyN1FieldsN1Label, unit: 'mmHg', error: s.hwLogErrorBodyN1FieldsN1Error, placeholder: '310', kind: TFieldKind.number)]),
        TBody(s.hwLogErrorBodyN2Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(label: s.hwLogErrorFooterN0Label, onPressed: null, arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.hwLogErrorFooterN1Label, onTap: () => TNav.replace(context, Routes.hwLog2)),
      ],
    );
  }
}
