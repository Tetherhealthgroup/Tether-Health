// GENERATED from spec/screens/records_consent_bb.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Consent: Medicare  ·  route `/records/consent?source=medicare`  ·  flow `records`  ·  kind `screen`
/// State: Medicare of records_consent · phase resources
/// 
///
/// Actions (generated from spec/screens/records_consent_bb.json):
///   • Back → back
///   • Continue to Medicare.gov → decide rec.consent.medicare: Anything selected? → Chosen: branch: Medicare sign-in result → Approved: push → records_importing | Cancelled: toast “Connection cancelled. Nothing was imported.” | Denied or error: push → records_error | Nothing chosen: toast “Select at least one item to continue.”
///   • Not now → back
/// API: —
class RecordsConsentBbScreen extends StatelessWidget {
  const RecordsConsentBbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsConsentBbHeaderTitle, pill: s.recordsConsentBbHeaderPill),
      children: [
        TTitle(s.recordsConsentBbBodyN0Text),
        TKeyValue(rows: [(s.recordsConsentBbBodyN1RowsN0N0, s.recordsConsentBbBodyN1RowsN0N1), (s.recordsConsentBbBodyN1RowsN1N0, s.recordsConsentBbBodyN1RowsN1N1), (s.recordsConsentBbBodyN1RowsN2N0, s.recordsConsentBbBodyN1RowsN2N1), (s.recordsConsentBbBodyN1RowsN3N0, s.recordsConsentBbBodyN1RowsN3N1)]),
        TChecklist(fieldKey: 'records_consent_bb.resources', items: [TCheckItem(s.recordsConsentBbBodyN2ItemsN0Label, value: 'Conditions', sub: s.recordsConsentBbBodyN2ItemsN0Sub), TCheckItem(s.recordsConsentBbBodyN2ItemsN1Label, value: 'Vital signs', sub: s.recordsConsentBbBodyN2ItemsN1Sub), TCheckItem(s.recordsConsentBbBodyN2ItemsN2Label, value: 'Lab results', sub: s.recordsConsentBbBodyN2ItemsN2Sub), TCheckItem(s.recordsConsentBbBodyN2ItemsN3Label, value: 'Medications', sub: s.recordsConsentBbBodyN2ItemsN3Sub), TCheckItem(s.recordsConsentBbBodyN2ItemsN4Label, value: 'Immunizations', sub: s.recordsConsentBbBodyN2ItemsN4Sub), TCheckItem(s.recordsConsentBbBodyN2ItemsN5Label, value: 'Smoking status', sub: s.recordsConsentBbBodyN2ItemsN5Sub)], label: s.recordsConsentBbBodyN2Label),
        TListGroup(flat: true, rows: [TListRow(label: s.recordsConsentBbBodyN3RowsN0Label, sub: s.recordsConsentBbBodyN3RowsN0Sub)]),
        TCard(variant: TCardVariant.mint, title: s.recordsConsentBbBodyN4Title, text: s.recordsConsentBbBodyN4Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsConsentBbFooterN0Label, onPressed: () => TNav.branch(context, 'Anything selected?', <String, VoidCallback>{'Chosen': () => TNav.branch(context, 'Medicare sign-in result', <String, VoidCallback>{'Approved': () => TNav.push(context, Routes.recordsImporting), 'Cancelled': () => TNav.toast(context, s.recordsConsentBbFooterN0ActionCasesN0ActionCasesN1ActionValue), 'Denied or error': () => TNav.push(context, Routes.recordsError)}, device: const TBranchRef('records.connect.medicare', TAsk.smartConnect, 'records_consent_bb'), when: const <TAnswer, String>{TAnswer.approved: 'Approved', TAnswer.cancelled: 'Cancelled', TAnswer.failed: 'Denied or error'}), 'Nothing chosen': () => TNav.toast(context, s.recordsConsentBbFooterN0ActionCasesN1ActionValue)}, decide: 'rec.consent.medicare'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.recordsConsentBbFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
