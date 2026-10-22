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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Nourish', pill: s.nuIntroHeaderPill),
      children: [
        TProgramTag(program: 'nu', extra: s.nuIntroBodyN0Extra),
        TTitle(s.nuIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.nuIntroBodyN2RowsN0N0, s.nuIntroBodyN2RowsN0N1), (s.nuIntroBodyN2RowsN1N0, s.nuIntroBodyN2RowsN1N1), (s.nuIntroBodyN2RowsN2N0, s.nuIntroBodyN2RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.nuIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.nuQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.nuIntroFooterN1Label, onPressed: () => TNav.toast(context, s.nuIntroFooterN1ActionValue, then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
