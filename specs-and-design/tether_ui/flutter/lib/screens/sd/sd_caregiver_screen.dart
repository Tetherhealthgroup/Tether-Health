// GENERATED from spec/screens/sd_caregiver.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Caregiver access  ·  route `/p/sd/caregiver`  ·  flow `sd`  ·  kind `screen`
/// Default state · program sd · phase account
/// 
///
/// Actions (generated from spec/screens/sd_caregiver.json):
///   • Back → back
///   • Send invite → POST /v1/care/caregivers then toast “Invite sent to Rosa” then back
/// API: —
class SdCaregiverScreen extends StatelessWidget {
  const SdCaregiverScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sdCaregiverHeaderTitle, pill: s.sdCaregiverHeaderPill),
      children: [
        TTitle(s.sdCaregiverBodyN0Text),
        TField(fieldKey: 'sd_caregiver.name', label: s.sdCaregiverBodyN1Label, placeholder: s.sdCaregiverBodyN1Placeholder),
        TField(fieldKey: 'sd_caregiver.phone', label: s.sdCaregiverBodyN2Label, placeholder: '(555) 010-2244', kind: TFieldKind.phone),
        TChecklist(fieldKey: 'sd_caregiver.caregiver_can_see', items: [TCheckItem(s.sdCaregiverBodyN3ItemsN0Label, value: 'When I finish a session', done: true), TCheckItem(s.sdCaregiverBodyN3ItemsN1Label, value: 'If I log a fall', done: true), TCheckItem(s.sdCaregiverBodyN3ItemsN2Label, value: 'My other programs', sub: s.sdCaregiverBodyN3ItemsN2Sub)], label: s.sdCaregiverBodyN3Label, bind: 'sd.caregiver.can_see'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sdCaregiverFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/care/caregivers', screenId: 'sd_caregiver', then: () => TNav.toast(context, s.sdCaregiverFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
