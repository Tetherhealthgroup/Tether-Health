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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugGateSumHeaderTitle, left: THeaderLeft.close, pill: 'Unplug'),
      children: [
        TTitle(s.sfUnplugGateSumBodyN0Text, size: TTitleSize.l),
        TBigNumber(value: '7 + 5', center: true),
        TField(fieldKey: 'sf_unplug_gate_sum.answer', label: s.sfUnplugGateSumBodyN2Label, placeholder: '?', kind: TFieldKind.number),
        TCard(variant: TCardVariant.coral, title: s.sfUnplugGateSumBodyN3Title, text: s.sfUnplugGateSumBodyN3Text, cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: s.sfUnplugGateSumBodyN3CtaN0Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugGateSumFooterN0Label, onPressed: () => TNav.toast(context, s.sfUnplugGateSumFooterN0ActionValue, then: () => TNav.reset(context, Routes.sfHome)), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.sfUnplugGateSumFooterN1Label, onTap: () => TNav.branch(context, 'Small step done?', <String, VoidCallback>{'Step done': () => TNav.toast(context, s.sfUnplugGateSumFooterN1ActionCasesN0ActionValue, then: () => TNav.reset(context, Routes.sfHome)), 'Step not done': () => TNav.toast(context, s.sfUnplugGateSumFooterN1ActionCasesN1ActionValue)}, decide: 'sf.unplug.sum')),
      ],
    );
  }
}
