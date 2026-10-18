// GENERATED from spec/screens/bf_slip.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Slip recovery  ·  route `/p/bf/slip`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase milestone
/// Append-only lapse event. No counter decreases.
///
/// Actions (generated from spec/screens/bf_slip.json):
///   • Close → close
///   • Save and start a 2-min Rescue → POST /v1/records/lapses then decide choice:bf_slip.next: Selected option → Continue from this moment: replace → rescue_active | Choose a new quit time: replace → bf_date
///   • Skip for now → back
/// API: POST /v1/records/lapses
class BfSlipScreen extends StatelessWidget {
  const BfSlipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Slip recovery', left: THeaderLeft.close, pill: 'Private'),
      children: [
        TEyebrow('Your progress is still here'),
        TTitle('A slip is information, not the end.'),
        TKeyValue(rows: [('Smoke-free days so far', '6 of 7 · kept')]),
        TChips(fieldKey: 'bf_slip.what_happened', options: ['A puff or two', 'One cigarette', 'More', 'Prefer not to say'], selected: ['A puff or two'], multi: false, label: 'What happened?'),
        TChips(fieldKey: 'bf_slip.what_was_going_on_optional', options: ['Stress', 'Around smokers', 'Alcohol', 'Scrolling late'], selected: ['Stress'], label: 'What was going on? (optional)'),
        TRadioList(fieldKey: 'bf_slip.next', items: [TRadioItem('Continue from this moment', sub: 'Keep your plan', badge: 'Recommended'), TRadioItem('Choose a new quit time')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save and start a 2-min Rescue', onPressed: () => TNav.submit(context, 'POST /v1/records/lapses', then: () => TNav.branch(context, 'Selected option', <String, VoidCallback>{'Continue from this moment': () => TNav.replace(context, Routes.rescueActive), 'Choose a new quit time': () => TNav.replace(context, Routes.bfDate)}, decide: 'choice:bf_slip.next')), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Skip for now', onTap: () => TNav.back(context)),
      ],
    );
  }
}
