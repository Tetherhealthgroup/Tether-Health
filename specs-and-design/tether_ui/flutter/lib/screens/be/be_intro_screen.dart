// GENERATED from spec/screens/be_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Beacon intro  ·  route `/p/be`  ·  flow `be`  ·  kind `screen`
/// Default state · program be · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/be_intro.json):
///   • Back → back
///   • Set up Beacon → push → be_q1
///   • Add as Learn only → POST /v1/enrolments then toast “Beacon added as Learn only” then tab → plans
/// API: POST /v1/enrolments
class BeIntroScreen extends StatelessWidget {
  const BeIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Beacon', pill: s.beIntroHeaderPill),
      children: [
        TProgramTag(program: 'be', extra: s.beIntroBodyN0Extra),
        TTitle(s.beIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.beIntroBodyN2RowsN0N0, s.beIntroBodyN2RowsN0N1), (s.beIntroBodyN2RowsN1N0, s.beIntroBodyN2RowsN1N1), (s.beIntroBodyN2RowsN2N0, s.beIntroBodyN2RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.beIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.beQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.beIntroFooterN1Label, onPressed: () => TNav.submit(context, 'POST /v1/enrolments', screenId: 'be_intro', queueable: false, then: () => TNav.toast(context, s.beIntroFooterN1ActionThenValue, then: () => TNav.tab(context, Routes.plans))), variant: TButtonVariant.secondary),
      ],
    );
  }
}
