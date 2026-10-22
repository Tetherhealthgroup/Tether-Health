// GENERATED from spec/screens/sf_slip.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Long-scroll recovery  ·  route `/p/sf/slip`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase milestone
/// 
///
/// Actions (generated from spec/screens/sf_slip.json):
///   • Back → back
///   • Save → POST /v1/records/lapses then toast “Saved” then replace → sf_home
/// API: —
class SfSlipScreen extends StatelessWidget {
  const SfSlipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfSlipHeaderTitle, pill: s.sfSlipHeaderPill),
      children: [
        TTitle(s.sfSlipBodyN0Text),
        TBody(s.sfSlipBodyN1Text, tone: TTextTone.muted),
        TChips(fieldKey: 'sf_slip.value', options: ['Couldn’t sleep', 'Bored', 'Stressed', 'Didn’t notice time'], labels: [s.sfSlipBodyN2OptionsN0, s.sfSlipBodyN2OptionsN1, s.sfSlipBodyN2OptionsN2, s.sfSlipBodyN2OptionsN3], selected: ['Couldn’t sleep']),
        TRadioList(fieldKey: 'sf_slip.value_2', items: [TRadioItem(s.sfSlipBodyN3ItemsN0Label, value: 'Keep my goal, try again tonight', badge: s.sfSlipBodyN3ItemsN0Badge), TRadioItem(s.sfSlipBodyN3ItemsN1Label, value: 'Make tomorrow’s goal easier'), TRadioItem(s.sfSlipBodyN3ItemsN2Label, value: 'Move bedtime window 30 min earlier')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfSlipFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/records/lapses', screenId: 'sf_slip', then: () => TNav.toast(context, s.sfSlipFooterN0ActionThenValue, then: () => TNav.replace(context, Routes.sfHome))), arrow: true),
      ],
    );
  }
}
