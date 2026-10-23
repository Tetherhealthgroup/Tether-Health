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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.reHistoryHeaderTitle, pill: 'Renew'),
      children: [
        TBoundValues(keys: const ['re.egfr_series'], builder: (context, v) => TLineChart(values: v.series('re.egfr_series', const [72.0, 69.0, 66.0, 64.0, 61.0, 58.0]), color: TColors.program('re'), title: s.reHistoryBodyN0Title, unit: 'mL/min', caption: s.reHistoryBodyN0Caption)),
        TBoundValues(keys: const ['re.egfr_latest_summary', 're.acr_latest', 're.next_check'], builder: (context, v) => TKeyValue(rows: [(s.reHistoryBodyN1RowsN0N0, v.text('re.egfr_latest_summary', s.reHistoryBodyN1RowsN0N1)), (s.reHistoryBodyN1RowsN1N0, v.text('re.acr_latest', s.reHistoryBodyN1RowsN1N1)), (s.reHistoryBodyN1RowsN2N0, v.text('re.next_check', s.reHistoryBodyN1RowsN2N1))])),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.reHistoryFooterN0Label, onPressed: () => TNav.push(context, Routes.hwSummary), variant: TButtonVariant.secondary),
      ],
    );
  }
}
