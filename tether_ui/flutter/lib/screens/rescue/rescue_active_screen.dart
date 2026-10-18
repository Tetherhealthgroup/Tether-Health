// GENERATED from spec/screens/rescue_active.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Active tool  ·  route `/rescue/breathing`  ·  flow `rescue`  ·  kind `fullscreen`
/// Default state · phase rescue
/// Timer pauses when the app is backgrounded. Reduce Motion → no scaling, countdown only.
///
/// Actions (generated from spec/screens/rescue_active.json):
///   • Close → close
///   • Switch tool → sheet → rescue_tools
///   • Get support → push → rescue_escalate
///   • I’m done → replace → rescue_result
/// API: —
class RescueActiveScreen extends StatelessWidget {
  const RescueActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Slow breathing', left: THeaderLeft.close, pill: '1:32 left'),
      background: TBackground.dark,
      children: [
        TEyebrow('Breathe out · slowly'),
        TBreathRing(value: '5'),
        TBody('The urge is a wave. Let it rise and pass.', center: true),
        TChips(fieldKey: 'rescue_active.value', options: ['Voice on', 'Haptics on', 'Reduced motion'], selected: ['Voice on', 'Haptics on']),
        TCard(variant: TCardVariant.dark2, title: 'Still strong?', text: 'Switch tool or reach a person. This check-in is kept.', children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[4].children[0].items[0]'), label: 'Switch tool', onPressed: () => TNav.sheet(context, Routes.rescueTools), variant: TButtonVariant.lime, small: true), TButton(key: const ValueKey('a:body[4].children[0].items[1]'), label: 'Get support', onPressed: () => TNav.push(context, Routes.rescueEscalate), variant: TButtonVariant.ghostDark, small: true)])]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'I’m done', onPressed: () => TNav.replace(context, Routes.rescueResult), variant: TButtonVariant.white, arrow: true),
      ],
    );
  }
}
