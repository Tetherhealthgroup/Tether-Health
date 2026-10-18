// GENERATED from spec/screens/ob_third.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Third program sheet  ·  route `/onboarding/focus/third`  ·  flow `onboarding`  ·  kind `sheet`
/// Default state · phase welcome
/// 
///
/// Actions (generated from spec/screens/ob_third.json):
///   • Continue → toast “Heartwise added as Learn only” then close
///   • Cancel → close
/// API: —
class ObThirdScreen extends StatelessWidget {
  const ObThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      children: [
        TEyebrow('Both focus slots are in use'),
        TTitle('Add Heartwise as…'),
        TRadioList(fieldKey: 'ob_third.value', items: [TRadioItem('Learn only for now', sub: 'Lessons, no reminders. Upgrade anytime.', badge: 'Suggested'), TRadioItem('Swap with ScrollFree', sub: 'ScrollFree pauses. Its data and progress are kept.'), TRadioItem('Swap with BreatheFree', sub: 'Not suggested during your quit week.')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue', onPressed: () => TNav.toast(context, 'Heartwise added as Learn only', then: () => TNav.close(context)), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
