// GENERATED from spec/screens/sf_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ScrollFree intro  ·  route `/p/sf`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/sf_intro.json):
///   • Back → back
///   • Set up ScrollFree → push → sf_q1
///   • Add as Learn only → toast “ScrollFree added as Learn only” then tab → plans
/// API: —
class SfIntroScreen extends StatelessWidget {
  const SfIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'ScrollFree', pill: '~1 min/day'),
      children: [
        TProgramTag(program: 'sf', extra: 'Social media use'),
        TTitle('Your attention is yours.', size: TTitleSize.l),
        TKeyValue(rows: [('Goal', 'minutes a day + app-free times'), ('Pause 60', 'intent check, not a lock'), ('Never', 'reads messages or feeds')]),
        TBody('Notice what pulls you in, set a goal that feels doable, and pause for 60 seconds when the urge hits.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up ScrollFree', onPressed: () => TNav.push(context, Routes.sfQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'ScrollFree added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
