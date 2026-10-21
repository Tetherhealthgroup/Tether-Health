// GENERATED from spec/screens/records_consent_device.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Consent: phone health data  ·  route `/records/consent?source=device`  ·  flow `records`  ·  kind `screen`
/// State: Apple Health / Health Connect of records_consent · phase resources
/// HealthKit clinical records (HKClinicalType) on iOS; Health Connect permissions on Android. Data stays on the device until you review it.
///
/// Actions (generated from spec/screens/records_consent_device.json):
///   • Back → back
///   • Continue → branch: System permission result → Allowed: push → records_importing | Not allowed: push → records_error
///   • Not now → back
/// API: —
class RecordsConsentDeviceScreen extends StatelessWidget {
  const RecordsConsentDeviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Connect', pill: 'Read-only'),
      children: [
        TTitle('Use health data on this phone?'),
        TBody('iPhone: Apple Health Records (FHIR) and readings. Android: Health Connect readings. You choose each type in the system screen next.', tone: TTextTone.muted),
        TChecklist(fieldKey: 'records_consent_device.data_types', items: [TCheckItem('Blood pressure', done: true), TCheckItem('Blood glucose', done: true), TCheckItem('Clinical records (iPhone)', sub: 'Labs, immunizations, conditions', done: true), TCheckItem('Steps and sleep', sub: 'Not requested')], label: 'What Tether will ask for'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue', onPressed: () => TNav.branch(context, 'System permission result', <String, VoidCallback>{'Allowed': () => TNav.push(context, Routes.recordsImporting), 'Not allowed': () => TNav.push(context, Routes.recordsError)}, device: const TBranchRef('records.device.health_records_request', TAsk.healthRecordsRequest, 'records_consent_device'), when: const <TAnswer, String>{TAnswer.granted: 'Allowed', TAnswer.denied: 'Not allowed', TAnswer.unavailable: 'Not allowed'}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Not now', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
