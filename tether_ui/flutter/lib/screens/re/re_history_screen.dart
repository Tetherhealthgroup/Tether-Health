// GENERATED from spec/screens/re_history.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Lab history  ·  route `/p/re/history`  ·  flow `re`  ·  kind `screen`
/// Default state · program re · phase resources
/// 
///
/// Actions (generated from spec/screens/re_history.json):
///   • Back → back
///   • Create visit summary → push → hw_summary
/// API: —
class ReHistoryScreen extends StatelessWidget {
  const ReHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Lab history', pill: 'Renew'),
      children: [
        TLineChart(values: [72.0, 69.0, 66.0, 64.0, 61.0, 58.0], color: TColors.program('re'), title: 'eGFR · 2 years', unit: 'mL/min', caption: 'Lower over time. Bring this to your next visit.'),
        TKeyValue(rows: [('Latest eGFR', '58 · Oct 3'), ('Latest ACR', '42 mg/g'), ('Next check', 'Apr 2027 (from your clinician)')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Create visit summary', onPressed: () => TNav.push(context, Routes.hwSummary), variant: TButtonVariant.secondary),
      ],
    );
  }
}
