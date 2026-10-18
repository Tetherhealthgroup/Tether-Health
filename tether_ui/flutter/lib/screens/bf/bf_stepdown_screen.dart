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
    return TScreen(
      header: THeader(title: 'Step-down schedule', pill: 'Plan 2 of 3'),
      children: [
        TTitle('Cut back at your pace.'),
        TBody('From your baseline of 15 a day. Adjust any week.', tone: TTextTone.muted),
        TKeyValue(rows: [('This week', '15 → 12 a day'), ('Week 2', '9 a day'), ('Week 3', '5 a day'), ('Week 4', '2 a day'), ('Quit day · Sep 18', '0')]),
        TCard(variant: TCardVariant.mint, text: 'Reducing works best paired with a quit date. Ask your clinician about nicotine replacement while cutting down.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save schedule', onPressed: () => TNav.push(context, Routes.bfSupport), arrow: true),
      ],
    );
  }
}
