// GENERATED from spec/screens/be_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Beacon intro  ·  route `/p/be`  ·  flow `be`  ·  kind `screen`
/// Default state · program be · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/be_intro.json):
///   • Back → back
///   • Set up Beacon → push → be_q1
///   • Add as Learn only → toast “Beacon added as Learn only” then tab → plans
/// API: —
class BeIntroScreen extends StatelessWidget {
  const BeIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Beacon', pill: '~1 min/week'),
      children: [
        TProgramTag(program: 'be', extra: 'Cancer'),
        TTitle('Lower your risk. Know your options.', size: TTitleSize.l),
        TKeyValue(rows: [('Risk steps', 'smoking, sun, alcohol, activity'), ('Screening', 'linked with Checkup'), ('Treatment support', 'questions, side-effect diary')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up Beacon', onPressed: () => TNav.push(context, Routes.beQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'Beacon added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
