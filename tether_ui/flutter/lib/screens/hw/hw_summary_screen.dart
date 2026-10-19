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
    return TScreen(
      header: THeader(title: 'Visit summary', pill: 'Preview'),
      children: [
        TTitle('Share with Dr. Patel’s clinic?'),
        TKeyValue(rows: [('Dates', 'Sep 17 – Oct 17'), ('BP average', '132/82 (48 readings)'), ('Highest', '186/122 · Oct 2 · re-checked 144/90'), ('Latest panel', 'LDL 138 · Sep 30')]),
        TBody('Only Heartwise data. Nothing from your other programs.', tone: TTextTone.small),
        TToggleRow(fieldKey: 'hw_summary.include_notes', label: 'Include notes'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Send summary', onPressed: () => TNav.submit(context, 'POST /v1/care/summaries', screenId: 'hw_summary', then: () => TNav.toast(context, 'Summary sent to Dr. Patel’s clinic', then: () => TNav.back(context))), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Save as PDF', onPressed: () => TNav.toast(context, 'PDF saved to Files'), variant: TButtonVariant.secondary),
      ],
    );
  }
}
