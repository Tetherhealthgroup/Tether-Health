// GENERATED from spec/screens/st_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Steady intro  ·  route `/p/st`  ·  flow `st`  ·  kind `screen`
/// Default state · program st · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/st_intro.json):
///   • Back → back
///   • Set up Steady → push → st_q1
///   • Add as Learn only → toast “Steady added as Learn only” then tab → plans
/// API: —
class StIntroScreen extends StatelessWidget {
  const StIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Steady', pill: '~2 min/day'),
      children: [
        TProgramTag(program: 'st', extra: 'Diabetes & metabolic health'),
        TTitle('Notice glucose patterns, without judgment.', size: TTitleSize.l),
        TKeyValue(rows: [('Readings', 'meter or CGM entries'), ('Range', 'from your clinician'), ('A high reading is', 'information, not failure')]),
        TBody('Log readings, see patterns around meals and sleep, and follow the low plan your clinician gave you. Steady never counts calories.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up Steady', onPressed: () => TNav.push(context, Routes.stQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'Steady added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
