// GENERATED from spec/screens/hw_log.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Log BP · reading 1  ·  route `/p/hw/log`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase daily
/// 
///
/// Actions (generated from spec/screens/hw_log.json):
///   • Back → back
///   • Next reading → push → hw_log2
/// API: —
class HwLogScreen extends StatelessWidget {
  const HwLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.hwLogHeaderTitle, pill: s.hwLogHeaderPill),
      children: [
        TTitle(s.hwLogBodyN0Text),
        TFieldRow(children: [TField(fieldKey: 'hw_log.systolic', label: s.hwLogBodyN1FieldsN0Label, unit: 'mmHg', placeholder: '138', kind: TFieldKind.number), TField(fieldKey: 'hw_log.diastolic', label: s.hwLogBodyN1FieldsN1Label, unit: 'mmHg', placeholder: '86', kind: TFieldKind.number)]),
        TField(fieldKey: 'hw_log.pulse_optional', label: s.hwLogBodyN2Label, unit: 'bpm', placeholder: '72', kind: TFieldKind.number),
        TChips(fieldKey: 'hw_log.value', options: ['Left arm', 'Right arm'], labels: [s.hwLogBodyN3OptionsN0, s.hwLogBodyN3OptionsN1], selected: ['Left arm'], multi: false),
        TCard(variant: TCardVariant.mint, title: s.hwLogBodyN4Title, text: s.hwLogBodyN4Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.hwLogFooterN0Label, onPressed: () => TNav.push(context, Routes.hwLog2), arrow: true),
      ],
    );
  }
}
