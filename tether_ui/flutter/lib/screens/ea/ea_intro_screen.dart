// GENERATED from spec/screens/ea_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Ease intro  ·  route `/p/ea`  ·  flow `ea`  ·  kind `screen`
/// Default state · program ea · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/ea_intro.json):
///   • Back → back
///   • Set up Ease → push → ea_q1
///   • Add as Learn only → toast “Ease added as Learn only” then tab → plans
/// API: —
class EaIntroScreen extends StatelessWidget {
  const EaIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Ease', pill: '~2 min/day'),
      children: [
        TProgramTag(program: 'ea', extra: 'Mental & behavioral health'),
        TTitle('Support for how you feel.', size: TTitleSize.l),
        TKeyValue(rows: [('Mood check-in', '30 seconds'), ('Screening', 'optional, private'), ('Help now', '988 always one tap away')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up Ease', onPressed: () => TNav.push(context, Routes.eaQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'Ease added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
