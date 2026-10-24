// GENERATED from spec/screens/hw_summary.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Visit summary  ·  route `/p/hw/summary`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase resources
/// 
///
/// Actions (generated from spec/screens/hw_summary.json):
///   • Back → back
///   • Send summary → POST /v1/care/summaries then toast “Summary sent to Dr. Patel’s clinic” then back
///   • Save as PDF → toast “PDF saved to Files”
/// API: —
class HwSummaryScreen extends StatelessWidget {
  const HwSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.hwSummaryHeaderTitle, pill: s.hwSummaryHeaderPill),
      children: [
        TBoundValues(keys: const ['hw.summary.title'], place: TExamplePlace.inline, builder: (context, v) => TTitle(v.text('hw.summary.title', s.hwSummaryBodyN0Text))),
        TBoundValues(keys: const ['hw.summary.dates', 'hw.summary.bp_average', 'hw.summary.highest', 'hw.summary.latest_panel'], builder: (context, v) => TKeyValue(rows: [(s.hwSummaryBodyN1RowsN0N0, v.text('hw.summary.dates', s.hwSummaryBodyN1RowsN0N1)), (s.hwSummaryBodyN1RowsN1N0, v.text('hw.summary.bp_average', s.hwSummaryBodyN1RowsN1N1)), (s.hwSummaryBodyN1RowsN2N0, v.text('hw.summary.highest', s.hwSummaryBodyN1RowsN2N1)), (s.hwSummaryBodyN1RowsN3N0, v.text('hw.summary.latest_panel', s.hwSummaryBodyN1RowsN3N1))])),
        TBody(s.hwSummaryBodyN2Text, tone: TTextTone.small),
        TToggleRow(fieldKey: 'hw_summary.include_notes', label: s.hwSummaryBodyN3Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.hwSummaryFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/care/summaries', screenId: 'hw_summary', then: () => TNav.toast(context, s.hwSummaryFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.hwSummaryFooterN1Label, onPressed: () => TNav.toast(context, s.hwSummaryFooterN1ActionValue), variant: TButtonVariant.secondary),
      ],
    );
  }
}
