// GENERATED from spec/screens/records_fhir_url.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Other FHIR server  ·  route `/records/fhir-url`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_fhir_url.json):
///   • Back → back
///   • Check and continue → branch: Server check → SMART on FHIR R4 supported: push → records_consent | Not a FHIR R4 server: push → records_error
/// API: GET {base}/.well-known/smart-configuration, GET {base}/metadata
class RecordsFhirUrlScreen extends StatelessWidget {
  const RecordsFhirUrlScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Other FHIR server'),
      children: [
        TTitle('Enter your provider’s FHIR address'),
        TField(fieldKey: 'records_fhir_url.base_url', label: 'FHIR server address', hint: 'Starts with https:// · your provider gives you this', placeholder: 'https://fhir.example-health.org/r4'),
        TBody('We check it supports SMART on FHIR R4 (/.well-known/smart-configuration) before you sign in.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Check and continue', onPressed: () => TNav.branch(context, 'Server check', <String, VoidCallback>{'SMART on FHIR R4 supported': () => TNav.push(context, Routes.recordsConsent), 'Not a FHIR R4 server': () => TNav.push(context, Routes.recordsError)}), arrow: true),
      ],
    );
  }
}
