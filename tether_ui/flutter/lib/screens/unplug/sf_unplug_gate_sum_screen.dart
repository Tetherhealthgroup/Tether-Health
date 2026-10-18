// GENERATED from spec/screens/sf_unplug_gate_sum.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Small step: quick sum  ·  route `/p/sf/unplug/step?state=sum`  ·  flow `unplug`  ·  kind `fullscreen`
/// State: quick sum of sf_unplug_gate · program sf · phase rescue
/// Copy needs clinical/legal review. Open it works only after the right answer is typed (rule sf.unplug.sum).
///
/// Actions (generated from spec/screens/sf_unplug_gate_sum.json):
///   • Close → close
///   • Get support → sheet → rescue_pick
///   • Keep it closed → toast “Nice. The app stays closed.” then reset → sf_home
///   • Open it for 10 minutes → decide sf.unplug.sum: Small step done? → Step done: toast “Open for 10 minutes. The pause screen comes back after.” then reset → sf_home | Step not done: toast “Answer the sum first.”
/// API: —
class SfUnplugGateSumScreen extends StatelessWidget {
  const SfUnplugGateSumScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Small step', left: THeaderLeft.close, pill: 'Unplug'),
      children: [
        TTitle('A quick sum, then decide.', size: TTitleSize.l),
        TBigNumber(value: '7 + 5', center: true),
        TField(fieldKey: 'sf_unplug_gate_sum.answer', label: 'Answer', placeholder: '?', kind: TFieldKind.number),
        TCard(variant: TCardVariant.coral, title: 'Need help right now?', text: 'Rescue opens in one tap.', cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: 'Get support', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Keep it closed', onPressed: () => TNav.toast(context, 'Nice. The app stays closed.', then: () => TNav.reset(context, Routes.sfHome)), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Open it for 10 minutes', onTap: () => TNav.branch(context, 'Small step done?', <String, VoidCallback>{'Step done': () => TNav.toast(context, 'Open for 10 minutes. The pause screen comes back after.', then: () => TNav.reset(context, Routes.sfHome)), 'Step not done': () => TNav.toast(context, 'Answer the sum first.')}, decide: 'sf.unplug.sum')),
      ],
    );
  }
}
