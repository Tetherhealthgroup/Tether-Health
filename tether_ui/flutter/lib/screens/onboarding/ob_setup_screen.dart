// GENERATED from spec/screens/ob_setup.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Set up focus programs  ·  route `/onboarding/setup`  ·  flow `onboarding`  ·  kind `screen`
/// Default state · phase onboarding
/// Hub for the onboarding context. Program setups return here (context.onboarding) instead of the program home.
///
/// Actions (generated from spec/screens/ob_setup.json):
///   • Back → back
///   • BreatheFree → push → bf_q1
///   • ScrollFree → push → sf_q1
///   • Health records (optional) → push → records_add
///   • Continue → push → ob_reminders
///   • Set up later → push → ob_reminders
/// API: —
class ObSetupScreen extends StatelessWidget {
  const ObSetupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    TFlow.onboarding = true; // program setups now return here
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.obSetupHeaderTitle, pill: s.obSetupHeaderPill),
      children: [
        TSteps(n: 5, total: 5),
        TTitle(s.obSetupBodyN1Text),
        TBody(s.obSetupBodyN2Text, tone: TTextTone.muted),
        TListGroup(title: s.obSetupBodyN3Title, rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'BreatheFree', sub: s.obSetupBodyN3RowsN0Sub, lead: TLead.program('bf'), pill: s.obSetupBodyN3RowsN0Pill, onTap: () => TNav.push(context, Routes.bfQ1)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'ScrollFree', sub: s.obSetupBodyN3RowsN1Sub, lead: TLead.program('sf'), pill: s.obSetupBodyN3RowsN1Pill, onTap: () => TNav.push(context, Routes.sfQ1))]),
        TListGroup(title: s.obSetupBodyN4Title, rows: [TListRow(label: 'ClearAir', sub: s.obSetupBodyN4RowsN0Sub, lead: TLead.program('ca'))]),
        TListGroup(title: s.obSetupBodyN5Title, rows: [TListRow(key: const ValueKey('a:body[5].rows[0]'), label: s.obSetupBodyN5RowsN0Label, sub: s.obSetupBodyN5RowsN0Sub, lead: TLead.icon('+'), onTap: () => TNav.push(context, Routes.recordsAdd))]),
        TCard(variant: TCardVariant.mint, title: s.obSetupBodyN6Title, text: s.obSetupBodyN6Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.obSetupFooterN0Label, onPressed: () => TNav.push(context, Routes.obReminders), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.obSetupFooterN1Label, onTap: () => TNav.push(context, Routes.obReminders)),
      ],
    );
  }
}
