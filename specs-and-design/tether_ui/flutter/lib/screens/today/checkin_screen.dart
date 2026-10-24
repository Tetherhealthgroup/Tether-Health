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
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TEyebrow(s.checkinBodyN0Text),
        TSegmented(fieldKey: 'checkin.how_do_you_feel_today', options: ['Low', 'Not great', 'Okay', 'Good', 'Great'], labels: [s.checkinBodyN1OptionsN0, s.checkinBodyN1OptionsN1, s.checkinBodyN1OptionsN2, s.checkinBodyN1OptionsN3, s.checkinBodyN1OptionsN4], selected: 'Okay', label: s.checkinBodyN1Label),
        TSegmented(fieldKey: 'checkin.stress_today', options: ['Low', 'Some', 'High'], labels: [s.checkinBodyN2OptionsN0, s.checkinBodyN2OptionsN1, s.checkinBodyN2OptionsN2], selected: 'High', label: s.checkinBodyN2Label),
        TCard(tag: 'bf', title: s.checkinBodyN3Title, text: s.checkinBodyN3Text, accent: 'bf', children: [TChips(fieldKey: 'checkin.value', options: ['No', 'A puff', 'One or more', 'Skip'], labels: [s.checkinBodyN3ChildrenN0OptionsN0, s.checkinBodyN3ChildrenN0OptionsN1, s.checkinBodyN3ChildrenN0OptionsN2, s.checkinBodyN3ChildrenN0OptionsN3], selected: ['One or more'], multi: false)]),
        TCard(tag: 'sf', title: s.checkinBodyN4Title, accent: 'sf', children: [TChips(fieldKey: 'checkin.value_2', options: ['Better', 'Same', 'Drained', 'Skip'], labels: [s.checkinBodyN4ChildrenN0OptionsN0, s.checkinBodyN4ChildrenN0OptionsN1, s.checkinBodyN4ChildrenN0OptionsN2, s.checkinBodyN4ChildrenN0OptionsN3], selected: ['Drained'], multi: false)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.checkinFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/records/check-ins', screenId: 'checkin', then: () => TNav.replace(context, Routes.checkinDone)), arrow: true),
        TBody(s.checkinFooterN1Text, tone: TTextTone.small, center: true),
      ],
    );
  }
}
