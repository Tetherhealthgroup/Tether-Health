// GENERATED from spec/screens/sd_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Stride intro  ·  route `/p/sd`  ·  flow `sd`  ·  kind `screen`
/// Default state · program sd · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/sd_intro.json):
///   • Back → back
///   • Set up Stride → push → sd_q1
///   • Add as Learn only → toast “Stride added as Learn only” then tab → plans
/// API: —
class SdIntroScreen extends StatelessWidget {
  const SdIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Stride', pill: s.sdIntroHeaderPill),
      children: [
        TProgramTag(program: 'sd', extra: s.sdIntroBodyN0Extra),
        TTitle(s.sdIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.sdIntroBodyN2RowsN0N0, s.sdIntroBodyN2RowsN0N1), (s.sdIntroBodyN2RowsN1N0, s.sdIntroBodyN2RowsN1N1), (s.sdIntroBodyN2RowsN2N0, s.sdIntroBodyN2RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sdIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.sdQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sdIntroFooterN1Label, onPressed: () => TNav.toast(context, s.sdIntroFooterN1ActionValue, then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
