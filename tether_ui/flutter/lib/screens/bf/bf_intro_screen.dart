// GENERATED from spec/screens/bf_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// BreatheFree intro  ·  route `/p/bf`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/bf_intro.json):
///   • Back → back
///   • Set up BreatheFree → push → bf_q1
///   • Add as Learn only → toast “BreatheFree added as Learn only” then tab → plans
/// API: —
class BfIntroScreen extends StatelessWidget {
  const BfIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'BreatheFree', pill: '~3 min/day'),
      children: [
        TProgramTag(program: 'bf', extra: 'Tobacco & nicotine'),
        TTitle('Your next breath can be different.', size: TTitleSize.l),
        TKeyValue(rows: [('Help when cravings hit', 'one tap, offline'), ('Plan your way', 'date · today · reduce · explore'), ('Medicines', 'education only')]),
        TBody('Plan, practice and get through cravings, with no judgment. A slip never erases your wins.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up BreatheFree', onPressed: () => TNav.push(context, Routes.bfQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'BreatheFree added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
