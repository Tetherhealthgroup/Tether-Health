// GENERATED from spec/screens/nu_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Nourish intro  ·  route `/p/nu`  ·  flow `nu`  ·  kind `screen`
/// Default state · program nu · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/nu_intro.json):
///   • Back → back
///   • Set up Nourish → push → nu_q1
///   • Add as Learn only → toast “Nourish added as Learn only” then tab → plans
/// API: —
class NuIntroScreen extends StatelessWidget {
  const NuIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Nourish', pill: '~1 min/day'),
      children: [
        TProgramTag(program: 'nu', extra: 'Obesity & nutrition'),
        TTitle('Food without judgment.', size: TTitleSize.l),
        TKeyValue(rows: [('Weekly habit', 'one at a time'), ('Weight', 'off by default'), ('Approach', 'add, don’t restrict')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up Nourish', onPressed: () => TNav.push(context, Routes.nuQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'Nourish added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
