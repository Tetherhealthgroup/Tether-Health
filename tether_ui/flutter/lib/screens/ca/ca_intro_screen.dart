// GENERATED from spec/screens/ca_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ClearAir intro  ·  route `/p/ca`  ·  flow `ca`  ·  kind `screen`
/// Default state · program ca · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/ca_intro.json):
///   • Back → back
///   • Set up ClearAir → push → ca_q1
///   • Add as Learn only → toast “ClearAir added as Learn only” then tab → plans
/// API: —
class CaIntroScreen extends StatelessWidget {
  const CaIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'ClearAir', pill: s.caIntroHeaderPill),
      children: [
        TProgramTag(program: 'ca', extra: s.caIntroBodyN0Extra),
        TTitle(s.caIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.caIntroBodyN2RowsN0N0, s.caIntroBodyN2RowsN0N1), (s.caIntroBodyN2RowsN1N0, s.caIntroBodyN2RowsN1N1), (s.caIntroBodyN2RowsN2N0, s.caIntroBodyN2RowsN2N1)]),
        TBody(s.caIntroBodyN3Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.caIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.caQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.caIntroFooterN1Label, onPressed: () => TNav.toast(context, s.caIntroFooterN1ActionValue, then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
