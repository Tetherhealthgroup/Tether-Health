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
    return TScreen(
      header: THeader(title: 'Heartwise', pill: '~2 min/day'),
      children: [
        TProgramTag(program: 'hw', extra: 'Cardiovascular health'),
        TTitle('Know your numbers. Share them on your terms.', size: TTitleSize.l),
        TKeyValue(rows: [('Readings', 'BP + cholesterol panels'), ('Targets', 'from your clinician'), ('A reading is', 'information, not a grade')]),
        TBody('Log blood pressure and cholesterol, see trends and prepare for visits. Both focus slots are in use, so you’ll choose how to add it.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up Heartwise', onPressed: () => TNav.sheet(context, Routes.focusFull), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'Heartwise added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
