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
    return TScreen(
      header: THeader(title: 'Small step', left: THeaderLeft.close, pill: 'Unplug'),
      children: [
        TTitle('One breath, then decide.', size: TTitleSize.l),
        TBreathRing(value: '30'),
        TBody('Breathe in as the circle grows, out as it shrinks.', center: true),
        TCard(variant: TCardVariant.coral, title: 'Need help right now?', text: 'Rescue opens in one tap.', cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: 'Get support', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Keep it closed', onPressed: () => TNav.toast(context, 'Nice. The app stays closed.', then: () => TNav.reset(context, Routes.sfHome)), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Open it for 10 minutes', onTap: () => TNav.toast(context, 'Open for 10 minutes. The pause screen comes back after.', then: () => TNav.reset(context, Routes.sfHome))),
      ],
    );
  }
}
