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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsConsentDeviceHeaderTitle, pill: s.recordsConsentDeviceHeaderPill),
      children: [
        TTitle(s.recordsConsentDeviceBodyN0Text),
        TBody(s.recordsConsentDeviceBodyN1Text, tone: TTextTone.muted),
        TChecklist(fieldKey: 'records_consent_device.data_types', items: [TCheckItem(s.recordsConsentDeviceBodyN2ItemsN0Label, value: 'Blood pressure'), TCheckItem(s.recordsConsentDeviceBodyN2ItemsN1Label, value: 'Blood glucose'), TCheckItem(s.recordsConsentDeviceBodyN2ItemsN2Label, value: 'Clinical records (iPhone)', sub: s.recordsConsentDeviceBodyN2ItemsN2Sub)], label: s.recordsConsentDeviceBodyN2Label),
        TListGroup(flat: true, rows: [TListRow(label: s.recordsConsentDeviceBodyN3RowsN0Label, sub: s.recordsConsentDeviceBodyN3RowsN0Sub)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsConsentDeviceFooterN0Label, onPressed: () => TNav.branch(context, 'Anything selected?', <String, VoidCallback>{'Chosen': () => TNav.branch(context, 'System permission result', <String, VoidCallback>{'Allowed': () => TNav.push(context, Routes.recordsImporting), 'Not allowed': () => TNav.push(context, Routes.recordsError)}, device: const TBranchRef('records.device.health_records_request', TAsk.healthRecordsRequest, 'records_consent_device'), when: const <TAnswer, String>{TAnswer.granted: 'Allowed', TAnswer.denied: 'Not allowed', TAnswer.unavailable: 'Not allowed'}), 'Nothing chosen': () => TNav.toast(context, s.recordsConsentDeviceFooterN0ActionCasesN1ActionValue)}, decide: 'rec.consent.device'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.recordsConsentDeviceFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
