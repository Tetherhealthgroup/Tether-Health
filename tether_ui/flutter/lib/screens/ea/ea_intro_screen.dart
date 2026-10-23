// GENERATED from spec/screens/ea_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Ease intro  ·  route `/p/ea`  ·  flow `ea`  ·  kind `screen`
/// Default state · program ea · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/ea_intro.json):
///   • Back → back
///   • Set up Ease → push → ea_q1
///   • Add as Learn only → POST /v1/enrolments then toast “Ease added as Learn only” then tab → plans
/// API: POST /v1/enrolments
class EaIntroScreen extends StatelessWidget {
  const EaIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Ease', pill: s.eaIntroHeaderPill),
      children: [
        TProgramTag(program: 'ea', extra: s.eaIntroBodyN0Extra),
        TTitle(s.eaIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.eaIntroBodyN2RowsN0N0, s.eaIntroBodyN2RowsN0N1), (s.eaIntroBodyN2RowsN1N0, s.eaIntroBodyN2RowsN1N1), (s.eaIntroBodyN2RowsN2N0, s.eaIntroBodyN2RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.eaIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.eaQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.eaIntroFooterN1Label, onPressed: () => TNav.submit(context, 'POST /v1/enrolments', screenId: 'ea_intro', queueable: false, then: () => TNav.toast(context, s.eaIntroFooterN1ActionThenValue, then: () => TNav.tab(context, Routes.plans))), variant: TButtonVariant.secondary),
      ],
    );
  }
}
