// GENERATED from spec/screens/support_message_care.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Message care team  ·  route `/support/care-team`  ·  flow `tabs`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/support_message_care.json):
///   • Back → back
///   • Call or text 988 → push → crisis
///   • Call 911 → call 911
///   • Send message → POST /v1/care/messages then toast “Message sent” then back
/// API: —
class SupportMessageCareScreen extends StatelessWidget {
  const SupportMessageCareScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.supportMessageCareHeaderTitle),
      children: [
        TBody(s.supportMessageCareBodyN0Text, tone: TTextTone.small),
        TField(fieldKey: 'support_message_care.topic', label: s.supportMessageCareBodyN1Label, placeholder: s.supportMessageCareBodyN1Placeholder, kind: TFieldKind.select),
        TField(fieldKey: 'support_message_care.message', label: s.supportMessageCareBodyN2Label, placeholder: s.supportMessageCareBodyN2Placeholder, kind: TFieldKind.multiline),
        TToggleRow(fieldKey: 'support_message_care.attach_a_summary', label: s.supportMessageCareBodyN3Label, sub: s.supportMessageCareBodyN3Sub),
        TEmergencyCard(text: s.supportMessageCareBodyN4Text, actions: [TButton(key: const ValueKey('a:body[4].actions[0]'), label: s.supportMessageCareBodyN4ActionsN0Label, onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[4].actions[1]'), label: s.supportMessageCareBodyN4ActionsN1Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.supportMessageCareFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/care/messages', screenId: 'support_message_care', then: () => TNav.toast(context, s.supportMessageCareFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
