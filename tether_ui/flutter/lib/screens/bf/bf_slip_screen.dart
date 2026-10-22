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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfSlipHeaderTitle, left: THeaderLeft.close, pill: s.bfSlipHeaderPill),
      children: [
        TEyebrow(s.bfSlipBodyN0Text),
        TTitle(s.bfSlipBodyN1Text),
        TKeyValue(rows: [(s.bfSlipBodyN2RowsN0N0, s.bfSlipBodyN2RowsN0N1)]),
        TChips(fieldKey: 'bf_slip.what_happened', options: ['A puff or two', 'One cigarette', 'More', 'Prefer not to say'], labels: [s.bfSlipBodyN3OptionsN0, s.bfSlipBodyN3OptionsN1, s.bfSlipBodyN3OptionsN2, s.bfSlipBodyN3OptionsN3], selected: ['A puff or two'], multi: false, label: s.bfSlipBodyN3Label),
        TChips(fieldKey: 'bf_slip.what_was_going_on_optional', options: ['Stress', 'Around smokers', 'Alcohol', 'Scrolling late'], labels: [s.bfSlipBodyN4OptionsN0, s.bfSlipBodyN4OptionsN1, s.bfSlipBodyN4OptionsN2, s.bfSlipBodyN4OptionsN3], selected: ['Stress'], label: s.bfSlipBodyN4Label),
        TRadioList(fieldKey: 'bf_slip.next', items: [TRadioItem(s.bfSlipBodyN5ItemsN0Label, value: 'Continue from this moment', sub: s.bfSlipBodyN5ItemsN0Sub, badge: s.bfSlipBodyN5ItemsN0Badge), TRadioItem(s.bfSlipBodyN5ItemsN1Label, value: 'Choose a new quit time')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfSlipFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/records/lapses', screenId: 'bf_slip', then: () => TNav.branch(context, 'Selected option', <String, VoidCallback>{'Continue from this moment': () => TNav.replace(context, Routes.rescueActive), 'Choose a new quit time': () => TNav.replace(context, Routes.bfDate)}, decide: 'choice:bf_slip.next')), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.bfSlipFooterN1Label, onTap: () => TNav.back(context)),
      ],
    );
  }
}
