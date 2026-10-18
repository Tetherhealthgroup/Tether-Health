// GENERATED from spec/screens/records_add.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Add a source  ·  route `/records/add`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_add.json):
///   • Back → back
///   • Hospital or clinic → push → records_search
///   • Oracle Health (Cerner) → push → records_search
///   • Medicare · Blue Button 2.0 → push → records_consent_bb
///   • Apple Health Records → push → records_consent_device
///   • Health Connect → push → records_consent_device
///   • Other FHIR server → push → records_fhir_url
///   • Enter manually → push → records_manual
/// API: —
class RecordsAddScreen extends StatelessWidget {
  const RecordsAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Add a source'),
      children: [
        TTitle('Where is your health information?'),
        TBody('You sign in with your provider. Tether never sees that password.', tone: TTextTone.muted),
        TListGroup(title: 'Connect', rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Hospital or clinic', sub: 'Epic MyChart · find yours', lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsSearch)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Oracle Health (Cerner)', sub: 'Patient portal', lead: TLead.icon('O'), onTap: () => TNav.push(context, Routes.recordsSearch)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Medicare · Blue Button 2.0', sub: 'Claims, prescriptions, diagnoses', lead: TLead.icon('M'), onTap: () => TNav.push(context, Routes.recordsConsentBb)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Apple Health Records', sub: 'iPhone · records you already added to Health', lead: TLead.icon(''), onTap: () => TNav.push(context, Routes.recordsConsentDevice)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: 'Health Connect', sub: 'Android · readings from your devices', lead: TLead.icon('H'), onTap: () => TNav.push(context, Routes.recordsConsentDevice)), TListRow(key: const ValueKey('a:body[2].rows[5]'), label: 'Other FHIR server', sub: 'Enter the address your provider gave you', lead: TLead.icon('F'), onTap: () => TNav.push(context, Routes.recordsFhirUrl))]),
        TListGroup(title: 'Or', rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Enter manually', sub: 'Type a value from a paper report', lead: TLead.icon('+'), onTap: () => TNav.push(context, Routes.recordsManual))]),
        TBody('Uses SMART on FHIR R4 with OAuth 2.0 + PKCE in your phone’s browser.', tone: TTextTone.small),
      ],
    );
  }
}
