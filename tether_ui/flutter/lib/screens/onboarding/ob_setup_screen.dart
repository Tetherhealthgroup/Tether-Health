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
    return TScreen(
      header: THeader(title: 'Set up', pill: '5 of 5'),
      children: [
        TSteps(n: 5, total: 5),
        TTitle('Let’s set up your programs.'),
        TBody('Each takes about 3 minutes. You can stop and come back.', tone: TTextTone.muted),
        TListGroup(title: 'Focus programs', rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'BreatheFree', sub: 'Quit plan · about 3 min', lead: TLead.program('bf'), pill: 'Start', onTap: () => TNav.push(context, Routes.bfQ1)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'ScrollFree', sub: 'Usage goal · about 2 min', lead: TLead.program('sf'), pill: 'Start', onTap: () => TNav.push(context, Routes.sfQ1))]),
        TListGroup(title: 'Learn only', rows: [TListRow(label: 'ClearAir', sub: 'Learn only · nothing to set up', lead: TLead.program('ca'))]),
        TListGroup(title: 'Your data', rows: [TListRow(key: const ValueKey('a:body[5].rows[0]'), label: 'Health records (optional)', sub: 'Import from Epic MyChart, Medicare or another FHIR source', lead: TLead.icon('+'), onTap: () => TNav.push(context, Routes.recordsAdd))]),
        TCard(variant: TCardVariant.mint, title: 'Tip', text: 'Finishing a program setup brings you back here.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue', onPressed: () => TNav.push(context, Routes.obReminders), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Set up later', onTap: () => TNav.push(context, Routes.obReminders)),
      ],
    );
  }
}
