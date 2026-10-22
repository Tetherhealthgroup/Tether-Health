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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsConflictHeaderTitle, pill: s.recordsConflictHeaderPill),
      children: [
        TCard(eyebrow: s.recordsConflictBodyN0Eyebrow, title: s.recordsConflictBodyN0Title, children: [TRadioList(fieldKey: 'records_conflict.a1c', items: [TRadioItem(s.recordsConflictBodyN0ChildrenN0ItemsN0Label, value: 'From Patel Family Medicine (Epic): 7.6%', sub: s.recordsConflictBodyN0ChildrenN0ItemsN0Sub), TRadioItem(s.recordsConflictBodyN0ChildrenN0ItemsN1Label, value: 'Entered by you: 7.4%', sub: s.recordsConflictBodyN0ChildrenN0ItemsN1Sub), TRadioItem(s.recordsConflictBodyN0ChildrenN0ItemsN2Label, value: 'Keep both', sub: s.recordsConflictBodyN0ChildrenN0ItemsN2Sub)], selected: -1)]),
        TCard(eyebrow: s.recordsConflictBodyN1Eyebrow, title: s.recordsConflictBodyN1Title, children: [TRadioList(fieldKey: 'records_conflict.bp', items: [TRadioItem(s.recordsConflictBodyN1ChildrenN0ItemsN0Label, value: 'Discard', sub: s.recordsConflictBodyN1ChildrenN0ItemsN0Sub), TRadioItem(s.recordsConflictBodyN1ChildrenN0ItemsN1Label, value: 'Keep as 129/80', sub: s.recordsConflictBodyN1ChildrenN0ItemsN1Sub), TRadioItem(s.recordsConflictBodyN1ChildrenN0ItemsN2Label, value: 'Ask my care team', sub: s.recordsConflictBodyN1ChildrenN0ItemsN2Sub)], selected: -1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsConflictFooterN0Label, onPressed: () => TNav.branch(context, 'Anything selected?', <String, VoidCallback>{'Chosen': () => TNav.submit(context, 'POST /v1/records/fhir/conflicts', screenId: 'records_conflict', then: () => TNav.toast(context, s.recordsConflictFooterN0ActionCasesN0ActionThenValue, then: () => TNav.back(context))), 'Nothing chosen': () => TNav.toast(context, s.recordsConflictFooterN0ActionCasesN1ActionValue)}, decide: 'rec.conflict'), arrow: true),
      ],
    );
  }
}
