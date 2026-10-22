// GENERATED from spec/screens/ck_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Checkup intro  ·  route `/p/ck`  ·  flow `ck`  ·  kind `screen`
/// Default state · program ck · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/ck_intro.json):
///   • Back → back
///   • Set up Checkup → push → ck_q1
///   • Add as Learn only → toast “Checkup added as Learn only” then tab → plans
/// API: —
class CkIntroScreen extends StatelessWidget {
  const CkIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Checkup', pill: s.ckIntroHeaderPill),
      children: [
        TProgramTag(program: 'ck', extra: s.ckIntroBodyN0Extra),
        TTitle(s.ckIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.ckIntroBodyN2RowsN0N0, s.ckIntroBodyN2RowsN0N1), (s.ckIntroBodyN2RowsN1N0, s.ckIntroBodyN2RowsN1N1), (s.ckIntroBodyN2RowsN2N0, s.ckIntroBodyN2RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.ckIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.ckQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.ckIntroFooterN1Label, onPressed: () => TNav.toast(context, s.ckIntroFooterN1ActionValue, then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
