// GENERATED from spec/screens/checkin.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Daily check-in  ·  route `/check-in`  ·  flow `today`  ·  kind `sheet`
/// Default state · phase daily
/// Each Focus program adds at most 2 questions. Any self-harm signal routes to Crisis.
///
/// Actions (generated from spec/screens/checkin.json):
///   • Save check-in → POST /v1/records/check-ins then replace → checkin_done
/// API: POST /v1/records/check-ins
class CheckinScreen extends StatelessWidget {
  const CheckinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      children: [
        TEyebrow('Shared · asked once'),
        TSegmented(fieldKey: 'checkin.how_do_you_feel_today', options: ['Low', 'Not great', 'Okay', 'Good', 'Great'], selected: 'Okay', label: 'How do you feel today?'),
        TSegmented(fieldKey: 'checkin.stress_today', options: ['Low', 'Some', 'High'], selected: 'High', label: 'Stress today'),
        TCard(tag: 'bf', title: 'Since your last check-in, did you smoke?', text: 'Before quit day this is expected, not a setback.', accent: 'bf', children: [TChips(fieldKey: 'checkin.value', options: ['No', 'A puff', 'One or more', 'Skip'], selected: ['One or more'], multi: false)]),
        TCard(tag: 'sf', title: 'How did you feel after scrolling yesterday?', accent: 'sf', children: [TChips(fieldKey: 'checkin.value_2', options: ['Better', 'Same', 'Drained', 'Skip'], selected: ['Drained'], multi: false)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save check-in', onPressed: () => TNav.submit(context, 'POST /v1/records/check-ins', screenId: 'checkin', then: () => TNav.replace(context, Routes.checkinDone)), arrow: true),
        TBody('Skip any program question', tone: TTextTone.small, center: true),
      ],
    );
  }
}
