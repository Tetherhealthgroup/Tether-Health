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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.supportConnectHeaderTitle),
      children: [
        TTitle(s.supportConnectBodyN0Text),
        TField(fieldKey: 'support_connect.invite_code', label: s.supportConnectBodyN1Label, placeholder: s.supportConnectBodyN1Placeholder),
        TBody(s.supportConnectBodyN2Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.supportConnectFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/care/connections', screenId: 'support_connect', then: () => TNav.toast(context, s.supportConnectFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
