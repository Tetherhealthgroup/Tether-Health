// GENERATED from spec/screens/sd_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Stride intro  ·  route `/p/sd`  ·  flow `sd`  ·  kind `screen`
/// Default state · program sd · phase welcome
/// Entry from Choose programs, Catalog or a Learn-only row.
///
/// Actions (generated from spec/screens/sd_intro.json):
///   • Back → back
///   • Set up Stride → push → sd_q1
///   • Add as Learn only → toast “Stride added as Learn only” then tab → plans
/// API: —
class SdIntroScreen extends StatelessWidget {
  const SdIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Stride', pill: '~10 min/day'),
      children: [
        TProgramTag(program: 'sd', extra: 'Healthy aging'),
        TTitle('Move well, stay well.', size: TTitleSize.l),
        TKeyValue(rows: [('Sessions', '5–15 min, audio + video'), ('Falls', 'home safety + I fell button'), ('Caregiver', 'optional, Stride only')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up Stride', onPressed: () => TNav.push(context, Routes.sdQ1), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Add as Learn only', onPressed: () => TNav.toast(context, 'Stride added as Learn only', then: () => TNav.tab(context, Routes.plans)), variant: TButtonVariant.secondary),
      ],
    );
  }
}
