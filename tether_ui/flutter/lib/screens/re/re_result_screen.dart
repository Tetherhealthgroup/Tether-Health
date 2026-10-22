// GENERATED from spec/screens/re_result.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Risk result  ·  route `/p/re/plan`  ·  flow `re`  ·  kind `screen`
/// Default state · program re · phase plan
/// 
///
/// Actions (generated from spec/screens/re_result.json):
///   • Back → back
///   • Also see Heartwise and Steady → push → catalog
///   • Save my plan → PUT /v1/program-data/re/plan then replace → re_home (onboarding: ob_setup)
/// API: —
class ReResultScreen extends StatelessWidget {
  const ReResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.reResultHeaderTitle, pill: s.reResultHeaderPill),
      children: [
        TTitle(s.reResultBodyN0Text),
        TCard(variant: TCardVariant.mint, text: s.reResultBodyN1Text),
        TCard(children: [TChecklist(items: [TCheckItem(s.reResultBodyN2ChildrenN0ItemsN0Label, value: 'Ask about eGFR and urine ACR at my next visit', done: true), TCheckItem(s.reResultBodyN2ChildrenN0ItemsN1Label, value: 'Remind me 1 week before my visit')])]),
        TCard(key: const ValueKey('a:body[3]'), title: s.reResultBodyN3Title, text: s.reResultBodyN3Text, onTap: () => TNav.push(context, Routes.catalog)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.reResultFooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/re/plan', screenId: 're_result', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.reHome))), arrow: true),
      ],
    );
  }
}
