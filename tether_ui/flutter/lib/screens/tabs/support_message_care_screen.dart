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
    return TScreen(
      header: THeader(title: 'Dr. Patel’s clinic'),
      children: [
        TBody('Secure message · usually replies within 1 business day. Not for emergencies.', tone: TTextTone.small),
        TField(fieldKey: 'support_message_care.topic', label: 'Topic', placeholder: 'Question about my plan', kind: TFieldKind.select),
        TField(fieldKey: 'support_message_care.message', label: 'Message', placeholder: 'I’ve been feeling dizzy in the mornings since starting the patch.', kind: TFieldKind.multiline),
        TToggleRow(fieldKey: 'support_message_care.attach_a_summary', label: 'Attach a summary', sub: 'You’ll preview it before sending'),
        TEmergencyCard(text: 'Chest pain, trouble breathing or thoughts of harming yourself? Call 911 · call or text 988.', actions: [TButton(key: const ValueKey('a:body[4].actions[0]'), label: 'Call or text 988', onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[4].actions[1]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Send message', onPressed: () => TNav.submit(context, 'POST /v1/care/messages', then: () => TNav.toast(context, 'Message sent', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
