// GENERATED from spec/screens/re_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Renew intro  ·  route `/p/re`  ·  flow `re`  ·  kind `screen`
/// Default state · program re · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/re_intro.json):
///   • Back → back
///   • Set up Renew → push → re_q1
///   • Add as Learn only → toast “Renew added as Learn only” then tab → plans
/// API: —
class ReIntroScreen extends StatelessWidget {
  const ReIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Renew', pill: '~1 min/day'),
      children: [
        TProgramTag(program: 're', extra: 'Kidney & liver health'),
        TTitle('Look after your kidneys and liver.', size: TTitleSize.l),
        TKeyValue(rows: [('Risk check', 'diabetes, BP, alcohol, family'), ('Labs', 'eGFR, ACR, ALT tracking'), ('Reminders', 'checks from your clinician')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up Renew', onPressed: () => TNav.push(context, Routes.reQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'Renew added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
