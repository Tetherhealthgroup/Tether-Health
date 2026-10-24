// GENERATED from spec/screens/focus_full.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Focus slots full  ·  route `/programs/focus-full`  ·  flow `plans`  ·  kind `sheet`
/// Default state · phase plan
/// 
///
/// Actions (generated from spec/screens/focus_full.json):
///   • Continue → decide choice:focus_full.option: Chosen option → Learn only: toast “Heartwise added as Learn only” then tab → plans | Swap: replace → hw_q1
///   • Cancel → close
/// API: —
class FocusFullScreen extends StatelessWidget {
  const FocusFullScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TEyebrow(s.focusFullBodyN0Text),
        TTitle(s.focusFullBodyN1Text),
        TRadioList(fieldKey: 'focus_full.option', items: [TRadioItem(s.focusFullBodyN2ItemsN0Label, value: 'Learn only for now', sub: s.focusFullBodyN2ItemsN0Sub, badge: s.focusFullBodyN2ItemsN0Badge), TRadioItem(s.focusFullBodyN2ItemsN1Label, value: 'Swap with ScrollFree', sub: s.focusFullBodyN2ItemsN1Sub), TRadioItem(s.focusFullBodyN2ItemsN2Label, value: 'Swap with BreatheFree', sub: s.focusFullBodyN2ItemsN2Sub)], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.focusFullFooterN0Label, onPressed: () => TNav.branch(context, 'Chosen option', <String, VoidCallback>{'Learn only': () => TNav.toast(context, s.focusFullFooterN0ActionCasesN0ActionValue, then: () => TNav.tab(context, Routes.plans)), 'Swap': () => TNav.replace(context, Routes.hwQ1)}, decide: 'choice:focus_full.option'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.focusFullFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
