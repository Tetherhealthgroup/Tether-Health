// GENERATED from spec/screens/ob_focus.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Focus slots  ·  route `/onboarding/focus`  ·  flow `onboarding`  ·  kind `screen`
/// Default state · phase welcome
/// 
///
/// Actions (generated from spec/screens/ob_focus.json):
///   • Back → back
///   • Add a third program → sheet → ob_third
///   • Continue → push → ob_consent
/// API: —
class ObFocusScreen extends StatelessWidget {
  const ObFocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your focus', pill: '2 of 5'),
      children: [
        TSteps(n: 2, total: 5),
        TTitle('Two at a time works best.'),
        TBody('Focus programs get daily steps and reminders. Learn only gives you lessons, with no tracking.', tone: TTextTone.muted),
        TListGroup(title: 'Focus · daily support', rows: [TListRow(label: 'BreatheFree', sub: 'About 3 min a day', lead: TLead.program('bf'), pill: 'Focus 1'), TListRow(label: 'ScrollFree', sub: 'About 1 min a day', lead: TLead.program('sf'), pill: 'Focus 2')]),
        TListGroup(title: 'Learn only · no reminders', rows: [TListRow(label: 'ClearAir', sub: 'Lessons about lung recovery', lead: TLead.program('ca'), pill: 'Learn')]),
        TCard(variant: TCardVariant.mint, title: 'Why two?', text: 'People keep going with fewer daily asks. Swap anytime in Account → Programs.'),
        TLink(key: const ValueKey('a:body[6]'), label: 'Add a third program', onTap: () => TNav.sheet(context, Routes.obThird)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue', onPressed: () => TNav.push(context, Routes.obConsent), arrow: true),
      ],
    );
  }
}
