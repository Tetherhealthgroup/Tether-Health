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
    return TScreen(
      header: THeader(title: 'Caregiver access', pill: 'Optional'),
      children: [
        TTitle('Let someone help'),
        TField(fieldKey: 'sd_caregiver.name', label: 'Name', placeholder: 'Rosa'),
        TField(fieldKey: 'sd_caregiver.phone', label: 'Phone', placeholder: '(555) 010-2244', kind: TFieldKind.phone),
        TChecklist(fieldKey: 'sd_caregiver.caregiver_can_see', items: [TCheckItem('When I finish a session', done: true), TCheckItem('If I log a fall', done: true), TCheckItem('My other programs', sub: 'Never available to caregivers')], label: 'Rosa can see'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Send invite', onPressed: () => TNav.submit(context, 'POST /v1/care/caregivers', screenId: 'sd_caregiver', then: () => TNav.toast(context, 'Invite sent to Rosa', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
