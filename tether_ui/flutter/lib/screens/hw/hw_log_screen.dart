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
    return TScreen(
      header: THeader(title: 'Log blood pressure', pill: '1 of 2'),
      children: [
        TTitle('Sit quietly for 5 minutes first.'),
        TFieldRow(children: [TField(fieldKey: 'hw_log.systolic', label: 'Top (systolic)', unit: 'mmHg', placeholder: '138', kind: TFieldKind.number), TField(fieldKey: 'hw_log.diastolic', label: 'Bottom (diastolic)', unit: 'mmHg', placeholder: '86', kind: TFieldKind.number)]),
        TField(fieldKey: 'hw_log.pulse_optional', label: 'Pulse (optional)', unit: 'bpm', placeholder: '72', kind: TFieldKind.number),
        TChips(fieldKey: 'hw_log.value', options: ['Left arm', 'Right arm'], selected: ['Left arm'], multi: false),
        TCard(variant: TCardVariant.mint, title: 'Tip', text: 'Take a second reading after 1 minute. We’ll average them.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next reading', onPressed: () => TNav.push(context, Routes.hwLog2), arrow: true),
      ],
    );
  }
}
