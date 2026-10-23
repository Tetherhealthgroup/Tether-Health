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
///   • Add as Learn only → POST /v1/enrolments then toast “Steady added as Learn only” then tab → plans
/// API: POST /v1/enrolments
class StIntroScreen extends StatelessWidget {
  const StIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Steady', pill: s.stIntroHeaderPill),
      children: [
        TProgramTag(program: 'st', extra: s.stIntroBodyN0Extra),
        TTitle(s.stIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.stIntroBodyN2RowsN0N0, s.stIntroBodyN2RowsN0N1), (s.stIntroBodyN2RowsN1N0, s.stIntroBodyN2RowsN1N1), (s.stIntroBodyN2RowsN2N0, s.stIntroBodyN2RowsN2N1)]),
        TBody(s.stIntroBodyN3Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.stIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.stQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.stIntroFooterN1Label, onPressed: () => TNav.submit(context, 'POST /v1/enrolments', screenId: 'st_intro', queueable: false, then: () => TNav.toast(context, s.stIntroFooterN1ActionThenValue, then: () => TNav.tab(context, Routes.plans))), variant: TButtonVariant.secondary),
      ],
    );
  }
}
