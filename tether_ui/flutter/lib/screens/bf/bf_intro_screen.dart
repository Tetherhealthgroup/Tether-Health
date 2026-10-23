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
///   • Add as Learn only → POST /v1/enrolments then toast “BreatheFree added as Learn only” then tab → plans
/// API: POST /v1/enrolments
class BfIntroScreen extends StatelessWidget {
  const BfIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'BreatheFree', pill: s.bfIntroHeaderPill),
      children: [
        TProgramTag(program: 'bf', extra: s.bfIntroBodyN0Extra),
        TTitle(s.bfIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.bfIntroBodyN2RowsN0N0, s.bfIntroBodyN2RowsN0N1), (s.bfIntroBodyN2RowsN1N0, s.bfIntroBodyN2RowsN1N1), (s.bfIntroBodyN2RowsN2N0, s.bfIntroBodyN2RowsN2N1)]),
        TBody(s.bfIntroBodyN3Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.bfQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.bfIntroFooterN1Label, onPressed: () => TNav.submit(context, 'POST /v1/enrolments', screenId: 'bf_intro', queueable: false, then: () => TNav.toast(context, s.bfIntroFooterN1ActionThenValue, then: () => TNav.tab(context, Routes.plans))), variant: TButtonVariant.secondary),
      ],
    );
  }
}
