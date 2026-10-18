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
    return TScreen(
      header: THeader(title: 'Quit date', pill: 'Plan 2 of 3'),
      children: [
        TTitle('Choose a day to begin.'),
        TBody('7–14 days away gives you time to prepare without losing momentum.', tone: TTextTone.muted),
        TCalendar(month: 'August 2026', selected: 28, window: [28, 29, 30, 31], today: 21),
        TCard(variant: TCardVariant.dark, eyebrow: 'Your quit date', title: 'Friday, August 28, 2026', text: '7 days to prepare · Pacific Time'),
        TToggleRow(fieldKey: 'bf_date.quit_day_check_in_at_7_00_am', label: 'Quit-day check-in at 7:00 AM', sub: 'Lock screen: “You have a Tether reminder.”', value: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Confirm this date', onPressed: () => TNav.push(context, Routes.bfSupport), arrow: true),
      ],
    );
  }
}
