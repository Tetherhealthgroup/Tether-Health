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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsFhirUrlHeaderTitle),
      children: [
        TTitle(s.recordsFhirUrlBodyN0Text),
        TField(fieldKey: 'records_fhir_url.base_url', label: s.recordsFhirUrlBodyN1Label, hint: s.recordsFhirUrlBodyN1Hint, placeholder: 'https://fhir.example-health.org/r4'),
        TBody(s.recordsFhirUrlBodyN2Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsFhirUrlFooterN0Label, onPressed: () => TNav.branch(context, 'Server check', <String, VoidCallback>{'SMART on FHIR R4 supported': () => TNav.push(context, Routes.recordsConsent), 'Not a FHIR R4 server': () => TNav.push(context, Routes.recordsError)}, device: const TBranchRef('records.fhir_url.server_check', TAsk.fhirServerCheck, 'records_fhir_url'), when: const <TAnswer, String>{TAnswer.supported: 'SMART on FHIR R4 supported', TAnswer.unsupported: 'Not a FHIR R4 server'}), arrow: true),
      ],
    );
  }
}
