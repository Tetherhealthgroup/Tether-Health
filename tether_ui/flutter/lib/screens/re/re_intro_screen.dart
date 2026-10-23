// GENERATED from spec/screens/re_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Renew intro  ·  route `/p/re`  ·  flow `re`  ·  kind `screen`
/// Default state · program re · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/re_intro.json):
///   • Back → back
///   • Set up Renew → push → re_q1
///   • Add as Learn only → POST /v1/enrolments then toast “Renew added as Learn only” then tab → plans
/// API: POST /v1/enrolments
class ReIntroScreen extends StatelessWidget {
  const ReIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Renew', pill: s.reIntroHeaderPill),
      children: [
        TProgramTag(program: 're', extra: s.reIntroBodyN0Extra),
        TTitle(s.reIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.reIntroBodyN2RowsN0N0, s.reIntroBodyN2RowsN0N1), (s.reIntroBodyN2RowsN1N0, s.reIntroBodyN2RowsN1N1), (s.reIntroBodyN2RowsN2N0, s.reIntroBodyN2RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.reIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.reQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.reIntroFooterN1Label, onPressed: () => TNav.submit(context, 'POST /v1/enrolments', screenId: 're_intro', queueable: false, then: () => TNav.toast(context, s.reIntroFooterN1ActionThenValue, then: () => TNav.tab(context, Routes.plans))), variant: TButtonVariant.secondary),
      ],
    );
  }
}
