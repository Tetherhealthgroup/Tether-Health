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
///   • Continue → decide rec.consent.device: Anything selected? → Chosen: branch: System permission result → Allowed: push → records_importing | Not allowed: push → records_error | Nothing chosen: toast “Select at least one item to continue.”
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
        TChecklist(fieldKey: 'records_consent_device.data_types', items: [TCheckItem('Blood pressure'), TCheckItem('Blood glucose'), TCheckItem('Clinical records (iPhone)', sub: 'Labs, immunizations, conditions')], label: 'What Tether will ask for'),
        TListGroup(flat: true, rows: [TListRow(label: 'Steps and sleep', sub: 'Not requested')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue', onPressed: () => TNav.branch(context, 'Anything selected?', <String, VoidCallback>{'Chosen': () => TNav.branch(context, 'System permission result', <String, VoidCallback>{'Allowed': () => TNav.push(context, Routes.recordsImporting), 'Not allowed': () => TNav.push(context, Routes.recordsError)}, device: const TBranchRef('records.device.health_records_request', TAsk.healthRecordsRequest, 'records_consent_device'), when: const <TAnswer, String>{TAnswer.granted: 'Allowed', TAnswer.denied: 'Not allowed', TAnswer.unavailable: 'Not allowed'}), 'Nothing chosen': () => TNav.toast(context, 'Select at least one item to continue.')}, decide: 'rec.consent.device'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Not now', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
