// GENERATED from spec/screens/support_connect.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Connect a clinic  ·  route `/support/connect`  ·  flow `tabs`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/support_connect.json):
///   • Back → back
///   • Connect → POST /v1/care/connections then toast “Connected to Dr. Patel’s clinic” then back
/// API: —
class SupportConnectScreen extends StatelessWidget {
  const SupportConnectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Connect a clinic'),
      children: [
        TTitle('Enter your clinic’s invite code'),
        TField(fieldKey: 'support_connect.invite_code', label: 'Invite code', placeholder: 'PATEL-4821'),
        TBody('Your clinic gave you this code. Connecting shares nothing until you approve a summary.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Connect', onPressed: () => TNav.submit(context, 'POST /v1/care/connections', screenId: 'support_connect', then: () => TNav.toast(context, 'Connected to Dr. Patel’s clinic', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
