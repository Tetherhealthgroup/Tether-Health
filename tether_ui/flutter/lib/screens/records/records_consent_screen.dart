// GENERATED from spec/screens/records_consent.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Consent: Epic  ·  route `/records/consent`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// Authorization code + PKCE in ASWebAuthenticationSession / Custom Tabs. The code is exchanged by records-service; refresh tokens are stored encrypted server-side, never on the phone.
///
/// Actions (generated from spec/screens/records_consent.json):
///   • Back → back
///   • Continue to MyChart → decide rec.consent.epic: Anything selected? → Chosen: branch: MyChart sign-in result → Approved: push → records_importing | Cancelled: toast “Connection cancelled. Nothing was imported.” | Denied or error: push → records_error | Nothing chosen: toast “Select at least one item to continue.”
///   • Not now → back
/// API: GET /v1/records/fhir/authorize (PKCE) → system browser, POST /v1/records/fhir/callback (code exchange on server)
class RecordsConsentScreen extends StatelessWidget {
  const RecordsConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsConsentHeaderTitle, pill: s.recordsConsentHeaderPill),
      children: [
        TTitle(s.recordsConsentBodyN0Text),
        TKeyValue(rows: [(s.recordsConsentBodyN1RowsN0N0, s.recordsConsentBodyN1RowsN0N1), (s.recordsConsentBodyN1RowsN1N0, s.recordsConsentBodyN1RowsN1N1), (s.recordsConsentBodyN1RowsN2N0, s.recordsConsentBodyN1RowsN2N1), (s.recordsConsentBodyN1RowsN3N0, s.recordsConsentBodyN1RowsN3N1)]),
        TChecklist(fieldKey: 'records_consent.resources', items: [TCheckItem(s.recordsConsentBodyN2ItemsN0Label, value: 'Conditions', sub: s.recordsConsentBodyN2ItemsN0Sub), TCheckItem(s.recordsConsentBodyN2ItemsN1Label, value: 'Vital signs', sub: s.recordsConsentBodyN2ItemsN1Sub), TCheckItem(s.recordsConsentBodyN2ItemsN2Label, value: 'Lab results', sub: s.recordsConsentBodyN2ItemsN2Sub), TCheckItem(s.recordsConsentBodyN2ItemsN3Label, value: 'Medications', sub: s.recordsConsentBodyN2ItemsN3Sub), TCheckItem(s.recordsConsentBodyN2ItemsN4Label, value: 'Immunizations', sub: s.recordsConsentBodyN2ItemsN4Sub), TCheckItem(s.recordsConsentBodyN2ItemsN5Label, value: 'Smoking status', sub: s.recordsConsentBodyN2ItemsN5Sub)], label: s.recordsConsentBodyN2Label),
        TListGroup(flat: true, rows: [TListRow(label: s.recordsConsentBodyN3RowsN0Label, sub: s.recordsConsentBodyN3RowsN0Sub)]),
        TCard(variant: TCardVariant.mint, title: s.recordsConsentBodyN4Title, text: s.recordsConsentBodyN4Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsConsentFooterN0Label, onPressed: () => TNav.branch(context, 'Anything selected?', <String, VoidCallback>{'Chosen': () => TNav.branch(context, 'MyChart sign-in result', <String, VoidCallback>{'Approved': () => TNav.push(context, Routes.recordsImporting), 'Cancelled': () => TNav.toast(context, s.recordsConsentFooterN0ActionCasesN0ActionCasesN1ActionValue), 'Denied or error': () => TNav.push(context, Routes.recordsError)}, device: const TBranchRef('records.connect.mychart', TAsk.smartConnect, 'records_consent'), when: const <TAnswer, String>{TAnswer.approved: 'Approved', TAnswer.cancelled: 'Cancelled', TAnswer.failed: 'Denied or error'}), 'Nothing chosen': () => TNav.toast(context, s.recordsConsentFooterN0ActionCasesN1ActionValue)}, decide: 'rec.consent.epic'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.recordsConsentFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
