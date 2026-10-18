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
    return TSheet(
      children: [
        TEyebrow('Both focus slots are in use'),
        TTitle('Add Heartwise as…'),
        TRadioList(fieldKey: 'focus_full.option', items: [TRadioItem('Learn only for now', sub: 'Lessons, no reminders. Upgrade anytime.', badge: 'Suggested'), TRadioItem('Swap with ScrollFree', sub: 'ScrollFree pauses. Its data is kept.'), TRadioItem('Swap with BreatheFree', sub: 'Not suggested during your quit week.')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue', onPressed: () => TNav.branch(context, 'Chosen option', <String, VoidCallback>{'Learn only': () => TNav.toast(context, 'Heartwise added as Learn only', then: () => TNav.tab(context, Routes.plans)), 'Swap': () => TNav.replace(context, Routes.hwQ1)}, decide: 'choice:focus_full.option'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
