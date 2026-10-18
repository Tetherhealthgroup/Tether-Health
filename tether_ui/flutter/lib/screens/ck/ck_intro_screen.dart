// GENERATED from spec/screens/ck_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Checkup intro  ·  route `/p/ck`  ·  flow `ck`  ·  kind `screen`
/// Default state · program ck · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/ck_intro.json):
///   • Back → back
///   • Set up Checkup → push → ck_q1
///   • Add as Learn only → toast “Checkup added as Learn only” then tab → plans
/// API: —
class CkIntroScreen extends StatelessWidget {
  const CkIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Checkup', pill: '~1 min/week'),
      children: [
        TProgramTag(program: 'ck', extra: 'Preventive health'),
        TTitle('What’s due for you, in one place.', size: TTitleSize.l),
        TKeyValue(rows: [('Personal list', 'USPSTF / CDC guidance'), ('Reminders', 'weekly, quiet'), ('Records', 'mark done, add dates')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up Checkup', onPressed: () => TNav.push(context, Routes.ckQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'Checkup added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
