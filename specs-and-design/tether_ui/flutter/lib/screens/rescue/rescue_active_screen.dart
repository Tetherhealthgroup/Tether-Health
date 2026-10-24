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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.rescueActiveHeaderTitle, left: THeaderLeft.close, pill: s.rescueActiveHeaderPill),
      background: TBackground.dark,
      children: [
        TEyebrow(s.rescueActiveBodyN0Text),
        TBreathRing(value: '5'),
        TBody(s.rescueActiveBodyN2Text, center: true),
        TChips(fieldKey: 'rescue_active.value', options: ['Voice on', 'Haptics on', 'Reduced motion'], labels: [s.rescueActiveBodyN3OptionsN0, s.rescueActiveBodyN3OptionsN1, s.rescueActiveBodyN3OptionsN2], selected: ['Voice on', 'Haptics on']),
        TCard(variant: TCardVariant.dark2, title: s.rescueActiveBodyN4Title, text: s.rescueActiveBodyN4Text, children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[4].children[0].items[0]'), label: s.rescueActiveBodyN4ChildrenN0ItemsN0Label, onPressed: () => TNav.sheet(context, Routes.rescueTools), variant: TButtonVariant.lime, small: true), TButton(key: const ValueKey('a:body[4].children[0].items[1]'), label: s.rescueActiveBodyN4ChildrenN0ItemsN1Label, onPressed: () => TNav.push(context, Routes.rescueEscalate), variant: TButtonVariant.ghostDark, small: true)])]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.rescueActiveFooterN0Label, onPressed: () => TNav.replace(context, Routes.rescueResult), variant: TButtonVariant.white, arrow: true),
      ],
    );
  }
}
