// GENERATED from spec/screens/bf_stepdown.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Step-down schedule  ·  route `/p/bf/plan/reduce`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase plan
/// 
///
/// Actions (generated from spec/screens/bf_stepdown.json):
///   • Back → back
///   • Save schedule → push → bf_support
/// API: —
class BfStepdownScreen extends StatelessWidget {
  const BfStepdownScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfStepdownHeaderTitle, pill: s.bfStepdownHeaderPill),
      children: [
        TTitle(s.bfStepdownBodyN0Text),
        TBody(s.bfStepdownBodyN1Text, tone: TTextTone.muted),
        TKeyValue(rows: [(s.bfStepdownBodyN2RowsN0N0, s.bfStepdownBodyN2RowsN0N1), (s.bfStepdownBodyN2RowsN1N0, s.bfStepdownBodyN2RowsN1N1), (s.bfStepdownBodyN2RowsN2N0, s.bfStepdownBodyN2RowsN2N1), (s.bfStepdownBodyN2RowsN3N0, s.bfStepdownBodyN2RowsN3N1), (s.bfStepdownBodyN2RowsN4N0, '0')]),
        TCard(variant: TCardVariant.mint, text: s.bfStepdownBodyN3Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfStepdownFooterN0Label, onPressed: () => TNav.push(context, Routes.bfSupport), arrow: true),
      ],
    );
  }
}
