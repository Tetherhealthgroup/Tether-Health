// GENERATED from spec/screens/sf_unplug_gate.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Small step: one breath  ·  route `/p/sf/unplug/step`  ·  flow `unplug`  ·  kind `fullscreen`
/// Default state · program sf · phase rescue
/// Copy needs clinical/legal review. The shield action hands off to the app because the step needs input the extension has no time or UI for. Clearing it grants the pass length the level allows. Get support opens Rescue without doing the step.
///
/// Actions (generated from spec/screens/sf_unplug_gate.json):
///   • Close → close
///   • Get support → sheet → rescue_pick
///   • Keep it closed → toast “Nice. The app stays closed.” then reset → sf_home
///   • Open it for 10 minutes → toast “Open for 10 minutes. The pause screen comes back after.” then reset → sf_home
/// API: —
class SfUnplugGateScreen extends StatelessWidget {
  const SfUnplugGateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugGateHeaderTitle, left: THeaderLeft.close, pill: 'Unplug'),
      children: [
        TTitle(s.sfUnplugGateBodyN0Text, size: TTitleSize.l),
        TBreathRing(value: '30'),
        TBody(s.sfUnplugGateBodyN2Text, center: true),
        TCard(variant: TCardVariant.coral, title: s.sfUnplugGateBodyN3Title, text: s.sfUnplugGateBodyN3Text, cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: s.sfUnplugGateBodyN3CtaN0Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugGateFooterN0Label, onPressed: () => TNav.toast(context, s.sfUnplugGateFooterN0ActionValue, then: () => TNav.reset(context, Routes.sfHome)), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.sfUnplugGateFooterN1Label, onTap: () => TNav.toast(context, s.sfUnplugGateFooterN1ActionValue, then: () => TNav.reset(context, Routes.sfHome))),
      ],
    );
  }
}
