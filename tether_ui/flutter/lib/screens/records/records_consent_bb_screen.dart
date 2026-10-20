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
///   • Continue to Medicare.gov → branch: Medicare sign-in result → Approved: push → records_importing | Cancelled: toast “Connection cancelled. Nothing was imported.” | Denied or error: push → records_error
///   • Not now → back
/// API: —
class RecordsConsentBbScreen extends StatelessWidget {
  const RecordsConsentBbScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Connect', pill: 'Read-only'),
      children: [
        TTitle('Connect Medicare?'),
        TKeyValue(rows: [('Source', 'CMS Blue Button 2.0 · FHIR R4 (claims)'), ('Access', 'Read-only'), ('Refresh', 'Daily while connected'), ('Stop', 'Disconnect anytime')]),
        TChecklist(fieldKey: 'records_consent_bb.resources', items: [TCheckItem('Conditions', sub: 'Condition', done: true), TCheckItem('Vital signs', sub: 'Observation · blood pressure, weight', done: true), TCheckItem('Lab results', sub: 'Observation · A1C, lipids, eGFR', done: true), TCheckItem('Medications', sub: 'MedicationRequest', done: true), TCheckItem('Immunizations', sub: 'Immunization', done: true), TCheckItem('Smoking status', sub: 'Observation · LOINC 72166-2', done: true), TCheckItem('Clinical notes', sub: 'Not requested')], label: 'What Tether will read'),
        TCard(variant: TCardVariant.mint, title: 'Only the programs you joined get data', text: 'Heartwise ← blood pressure, lipids · Steady ← A1C, glucose · Renew ← eGFR · Checkup ← immunizations · BreatheFree ← smoking status. Ease and ScrollFree get nothing.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue to Medicare.gov', onPressed: () => TNav.branch(context, 'Medicare sign-in result', <String, VoidCallback>{'Approved': () => TNav.push(context, Routes.recordsImporting), 'Cancelled': () => TNav.toast(context, 'Connection cancelled. Nothing was imported.'), 'Denied or error': () => TNav.push(context, Routes.recordsError)}, device: const TBranchRef('records.connect.medicare', TAsk.smartConnect, 'records_consent_bb'), when: const <TAnswer, String>{TAnswer.approved: 'Approved', TAnswer.cancelled: 'Cancelled', TAnswer.failed: 'Denied or error'}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Not now', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
