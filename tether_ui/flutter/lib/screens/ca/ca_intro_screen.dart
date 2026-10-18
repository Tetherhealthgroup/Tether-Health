// GENERATED from spec/screens/ca_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ClearAir intro  ·  route `/p/ca`  ·  flow `ca`  ·  kind `screen`
/// Default state · program ca · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/ca_intro.json):
///   • Back → back
///   • Set up ClearAir → push → ca_q1
///   • Add as Learn only → toast “ClearAir added as Learn only” then tab → plans
/// API: —
class CaIntroScreen extends StatelessWidget {
  const CaIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'ClearAir', pill: '~1 min/day'),
      children: [
        TProgramTag(program: 'ca', extra: 'Respiratory health'),
        TTitle('Follow your action plan, day by day.', size: TTitleSize.l),
        TKeyValue(rows: [('Zone check', 'green · yellow · red'), ('Red zone', 'one tap to 911'), ('Zones', 'from your clinician only')]),
        TBody('Check your zone, log symptoms and know exactly what to do, using the plan your clinician gave you.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up ClearAir', onPressed: () => TNav.push(context, Routes.caQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'ClearAir added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
