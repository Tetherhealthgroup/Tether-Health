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
///   • Continue to MyChart → branch: MyChart sign-in result → Approved: push → records_importing | Cancelled: toast “Connection cancelled. Nothing was imported.” | Denied or error: push → records_error
///   • Not now → back
/// API: GET /v1/records/fhir/authorize (PKCE) → system browser, POST /v1/records/fhir/callback (code exchange on server)
class RecordsConsentScreen extends StatelessWidget {
  const RecordsConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Connect', pill: 'Read-only'),
      children: [
        TTitle('Connect Patel Family Medicine?'),
        TKeyValue(rows: [('Source', 'Epic MyChart · SMART on FHIR R4'), ('Access', 'Read-only'), ('Refresh', 'Daily while connected'), ('Stop', 'Disconnect anytime')]),
        TChecklist(items: [TCheckItem('Conditions', sub: 'Condition', done: true), TCheckItem('Vital signs', sub: 'Observation · blood pressure, weight', done: true), TCheckItem('Lab results', sub: 'Observation · A1C, lipids, eGFR', done: true), TCheckItem('Medications', sub: 'MedicationRequest', done: true), TCheckItem('Immunizations', sub: 'Immunization', done: true), TCheckItem('Smoking status', sub: 'Observation · LOINC 72166-2', done: true), TCheckItem('Clinical notes', sub: 'Not requested')], label: 'What Tether will read'),
        TCard(variant: TCardVariant.mint, title: 'Only the programs you joined get data', text: 'Heartwise ← blood pressure, lipids · Steady ← A1C, glucose · Renew ← eGFR · Checkup ← immunizations · BreatheFree ← smoking status. Ease and ScrollFree get nothing.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue to MyChart', onPressed: () => TNav.branch(context, 'MyChart sign-in result', <String, VoidCallback>{'Approved': () => TNav.push(context, Routes.recordsImporting), 'Cancelled': () => TNav.toast(context, 'Connection cancelled. Nothing was imported.'), 'Denied or error': () => TNav.push(context, Routes.recordsError)}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Not now', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
