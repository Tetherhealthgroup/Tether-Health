// GENERATED from spec/screens/support.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Support  ·  route `/support`  ·  flow `tabs`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/support.json):
///   • Avatar · Account → push → account
///   • Call now → call 1-800-784-8669
///   • Request call-back → sheet → support_callback
///   • Jordan → sheet → support_message
///   • Add a ScrollFree buddy → push → sf_buddy
///   • Dr. Patel’s clinic → push → support_message_care
///   • Call or text 988 → push → crisis
///   • Call 911 → call 911
///   • Tab · Today → tab → today
///   • Tab · Plans → tab → plans
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
/// API: —
class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.supportHeaderTitle, left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'support',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: s.supportBodyN0Eyebrow, title: s.supportBodyN0Title, text: s.supportBodyN0Text, children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[0].children[0].items[0]'), label: s.supportBodyN0ChildrenN0ItemsN0Label, onPressed: () => TNav.call(context, '1-800-784-8669', label: 'Call 1-800-QUIT-NOW'), variant: TButtonVariant.lime, small: true), TButton(key: const ValueKey('a:body[0].children[0].items[1]'), label: s.supportBodyN0ChildrenN0ItemsN1Label, onPressed: () => TNav.sheet(context, Routes.supportCallback), variant: TButtonVariant.ghostDark, small: true)])]),
        TListGroup(title: s.supportBodyN1Title, rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: s.supportBodyN1RowsN0Label, sub: s.supportBodyN1RowsN0Sub, lead: TLead.avatar('J'), onTap: () => TNav.sheet(context, Routes.supportMessage)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: s.supportBodyN1RowsN1Label, lead: TLead.icon('+'), onTap: () => TNav.push(context, Routes.sfBuddy))]),
        TListGroup(title: s.supportBodyN2Title, rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.supportBodyN2RowsN0Label, sub: s.supportBodyN2RowsN0Sub, lead: TLead.icon('+'), onTap: () => TNav.push(context, Routes.supportMessageCare))]),
        TEmergencyCard(text: s.supportBodyN3Text, actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: s.supportBodyN3ActionsN0Label, onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[3].actions[1]'), label: s.supportBodyN3ActionsN1Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
    );
  }
}
