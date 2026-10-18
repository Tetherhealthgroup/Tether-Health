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
    return TScreen(
      header: THeader(title: 'Your result', pill: 'Not a diagnosis'),
      children: [
        TTitle('Worth asking about a kidney check.'),
        TCard(variant: TCardVariant.mint, text: 'People with diabetes and high blood pressure are usually advised to have yearly kidney tests: a blood test (eGFR) and a urine test (ACR).'),
        TCard(children: [TChecklist(items: [TCheckItem('Ask about eGFR and urine ACR at my next visit', done: true), TCheckItem('Remind me 1 week before my visit')])]),
        TCard(key: const ValueKey('a:body[3]'), title: 'Also see Heartwise and Steady', text: 'Managing BP and glucose protects your kidneys.', onTap: () => TNav.push(context, Routes.catalog)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save my plan', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/re/plan', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.reHome))), arrow: true),
      ],
    );
  }
}
