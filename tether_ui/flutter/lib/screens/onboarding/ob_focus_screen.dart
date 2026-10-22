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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.obFocusHeaderTitle, pill: s.obFocusHeaderPill),
      children: [
        TSteps(n: 2, total: 5),
        TTitle(s.obFocusBodyN1Text),
        TBody(s.obFocusBodyN2Text, tone: TTextTone.muted),
        TListGroup(title: s.obFocusBodyN3Title, rows: [TListRow(label: 'BreatheFree', sub: s.obFocusBodyN3RowsN0Sub, lead: TLead.program('bf'), pill: s.obFocusBodyN3RowsN0Pill), TListRow(label: 'ScrollFree', sub: s.obFocusBodyN3RowsN1Sub, lead: TLead.program('sf'), pill: s.obFocusBodyN3RowsN1Pill)]),
        TListGroup(title: s.obFocusBodyN4Title, rows: [TListRow(label: 'ClearAir', sub: s.obFocusBodyN4RowsN0Sub, lead: TLead.program('ca'), pill: s.obFocusBodyN4RowsN0Pill)]),
        TCard(variant: TCardVariant.mint, title: s.obFocusBodyN5Title, text: s.obFocusBodyN5Text),
        TLink(key: const ValueKey('a:body[6]'), label: s.obFocusBodyN6Label, onTap: () => TNav.sheet(context, Routes.obThird)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.obFocusFooterN0Label, onPressed: () => TNav.push(context, Routes.obConsent), arrow: true),
      ],
    );
  }
}
