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
    return TScreen(
      header: THeader(title: 'Long scroll', pill: 'Private'),
      children: [
        TTitle('That happens. What pulled you in?'),
        TBody('Nothing resets. Your phone-free nights still count.', tone: TTextTone.muted),
        TChips(fieldKey: 'sf_slip.value', options: ['Couldn’t sleep', 'Bored', 'Stressed', 'Didn’t notice time'], selected: ['Couldn’t sleep']),
        TRadioList(fieldKey: 'sf_slip.value_2', items: [TRadioItem('Keep my goal, try again tonight', badge: 'Recommended'), TRadioItem('Make tomorrow’s goal easier'), TRadioItem('Move bedtime window 30 min earlier')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'POST /v1/records/lapses', screenId: 'sf_slip', then: () => TNav.toast(context, 'Saved', then: () => TNav.replace(context, Routes.sfHome))), arrow: true),
      ],
    );
  }
}
