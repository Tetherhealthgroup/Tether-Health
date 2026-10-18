// GENERATED from spec/screens/support_empty.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Support · empty  ·  route `/support?state=empty`  ·  flow `tabs`  ·  kind `screen`
/// State: empty of support · phase resources
/// 
///
/// Actions (generated from spec/screens/support_empty.json):
///   • Avatar · Account → push → account
///   • Call → call 1-800-784-8669
///   • Add → push → support_add_person
///   • Connect → push → support_connect
///   • Call or text 988 → push → crisis
///   • Call 911 → call 911
///   • Tab · Today → tab → today
///   • Tab · Plans → tab → plans
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
/// API: —
class SupportEmptyScreen extends StatelessWidget {
  const SupportEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Support', left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'support',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'Free & confidential', title: 'Quitline counselor', cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: 'Call', onPressed: () => TNav.call(context, '1-800-784-8669', label: 'Call 1-800-QUIT-NOW'), variant: TButtonVariant.lime, small: true)),
        TCard(eyebrow: 'Your people', title: 'No one added yet', text: 'A friend or family member gets a short help phrase from you, only when you choose to send it.', cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: 'Add', onPressed: () => TNav.push(context, Routes.supportAddPerson), small: true)),
        TCard(eyebrow: 'Care team', title: 'Not connected', text: 'Connect a clinic to share summaries you approve.', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Connect', onPressed: () => TNav.push(context, Routes.supportConnect), variant: TButtonVariant.secondary, small: true)),
        TEmergencyCard(text: 'Thoughts of harming yourself? Call or text 988. Emergency: 911.', actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: 'Call or text 988', onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[3].actions[1]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
    );
  }
}
