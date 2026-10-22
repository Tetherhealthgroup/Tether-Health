// GENERATED from spec/screens/hw_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Heartwise intro  ·  route `/p/hw`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/hw_intro.json):
///   • Back → back
///   • Set up Heartwise → sheet → focus_full
///   • Add as Learn only → toast “Heartwise added as Learn only” then tab → plans
/// API: —
class HwIntroScreen extends StatelessWidget {
  const HwIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Heartwise', pill: s.hwIntroHeaderPill),
      children: [
        TProgramTag(program: 'hw', extra: s.hwIntroBodyN0Extra),
        TTitle(s.hwIntroBodyN1Text, size: TTitleSize.l),
        TKeyValue(rows: [(s.hwIntroBodyN2RowsN0N0, s.hwIntroBodyN2RowsN0N1), (s.hwIntroBodyN2RowsN1N0, s.hwIntroBodyN2RowsN1N1), (s.hwIntroBodyN2RowsN2N0, s.hwIntroBodyN2RowsN2N1)]),
        TBody(s.hwIntroBodyN3Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.hwIntroFooterN0Label, onPressed: () => TNav.sheet(context, Routes.focusFull), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.hwIntroFooterN1Label, onPressed: () => TNav.toast(context, s.hwIntroFooterN1ActionValue, then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
