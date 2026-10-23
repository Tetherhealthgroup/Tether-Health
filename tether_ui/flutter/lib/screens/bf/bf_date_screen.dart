// GENERATED from spec/screens/bf_date.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Select quit date  ·  route `/p/bf/plan/date`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase plan
/// 
///
/// Actions (generated from spec/screens/bf_date.json):
///   • Back → back
///   • Confirm this date → push → bf_support
/// API: —
class BfDateScreen extends StatelessWidget {
  const BfDateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfDateHeaderTitle, pill: s.bfDateHeaderPill),
      children: [
        TTitle(s.bfDateBodyN0Text),
        TBody(s.bfDateBodyN1Text, tone: TTextTone.muted),
        TCalendar(fieldKey: 'bf_date.quit_date', month: s.bfDateBodyN2Month, selected: 28, window: [28, 29, 30, 31], today: 21, year: 2026, monthNumber: 8),
        TDateSummary(fieldKey: 'bf_date.quit_date', eyebrow: s.bfDateBodyN3Eyebrow, design: TCard(variant: TCardVariant.dark, eyebrow: s.bfDateBodyN3Eyebrow, title: s.bfDateBodyN3Title, text: s.bfDateBodyN3Text)),
        TToggleRow(fieldKey: 'bf_date.quit_day_check_in_at_7_00_am', label: s.bfDateBodyN4Label, sub: s.bfDateBodyN4Sub, value: true),
      ],
      footer: [
        TGatedButton(key: const ValueKey('a:footer[0]'), fieldKey: 'bf_date.quit_date', label: s.bfDateFooterN0Label, onPressed: () => TNav.push(context, Routes.bfSupport), arrow: true),
      ],
    );
  }
}
