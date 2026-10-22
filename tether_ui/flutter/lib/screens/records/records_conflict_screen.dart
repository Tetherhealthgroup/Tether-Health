// GENERATED from spec/screens/records_conflict.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Resolve conflicts  ·  route `/records/conflicts`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_conflict.json):
///   • Back → back
///   • Save choices → decide rec.conflict: Anything selected? → Chosen: POST /v1/records/fhir/conflicts then toast “Saved” then back | Nothing chosen: toast “Choose an option for at least one item.”
/// API: —
class RecordsConflictScreen extends StatelessWidget {
  const RecordsConflictScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Needs review', pill: '2 items'),
      children: [
        TCard(eyebrow: 'A1C · Oct 1, 2026', title: 'Two values for the same test', children: [TRadioList(fieldKey: 'records_conflict.a1c', items: [TRadioItem('From Patel Family Medicine (Epic): 7.6%', sub: 'Lab result · final · LOINC 4548-4'), TRadioItem('Entered by you: 7.4%', sub: 'Oct 1, 2026'), TRadioItem('Keep both', sub: 'Your clinician’s value is used in summaries')], selected: -1)]),
        TCard(eyebrow: 'Blood pressure · Aug 4, 2026', title: '1290/80 is outside the possible range', children: [TRadioList(fieldKey: 'records_conflict.bp', items: [TRadioItem('Discard', sub: 'Likely a typo in the source'), TRadioItem('Keep as 129/80', sub: 'Corrected by you, marked as edited'), TRadioItem('Ask my care team', sub: 'Sends a question with the original value')], selected: -1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save choices', onPressed: () => TNav.branch(context, 'Anything selected?', <String, VoidCallback>{'Chosen': () => TNav.submit(context, 'POST /v1/records/fhir/conflicts', screenId: 'records_conflict', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), 'Nothing chosen': () => TNav.toast(context, 'Choose an option for at least one item.')}, decide: 'rec.conflict'), arrow: true),
      ],
    );
  }
}
