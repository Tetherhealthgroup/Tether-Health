// GENERATED from spec/screens/sf_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ScrollFree intro  ·  route `/p/sf`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/sf_intro.json):
///   • Back → back
///   • Set up ScrollFree → push → sf_q1
///   • Add as Learn only → POST /v1/enrolments then toast “ScrollFree added as Learn only” then tab → plans
/// API: POST /v1/enrolments
class SfIntroScreen extends StatelessWidget {
  const SfIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'ScrollFree', pill: s.sfIntroHeaderPill),
      children: [
        TProgramTag(program: 'sf', extra: s.sfIntroBodyN0Extra),
        TTitle(s.sfIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.sfIntroBodyN2RowsN0N0, s.sfIntroBodyN2RowsN0N1), (s.sfIntroBodyN2RowsN1N0, s.sfIntroBodyN2RowsN1N1), (s.sfIntroBodyN2RowsN2N0, s.sfIntroBodyN2RowsN2N1)]),
        TBody(s.sfIntroBodyN3Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfIntroFooterN0Label, onPressed: () => TNav.push(context, Routes.sfQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfIntroFooterN1Label, onPressed: () => TNav.submit(context, 'POST /v1/enrolments', screenId: 'sf_intro', queueable: false, then: () => TNav.toast(context, s.sfIntroFooterN1ActionThenValue, then: () => TNav.tab(context, Routes.plans))), variant: TButtonVariant.secondary),
      ],
    );
  }
}
