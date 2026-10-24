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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.supportEmptyHeaderTitle, left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'support',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: s.supportEmptyBodyN0Eyebrow, title: s.supportEmptyBodyN0Title, cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: s.supportEmptyBodyN0CtaN0Label, onPressed: () => TNav.call(context, '1-800-784-8669', label: 'Call 1-800-QUIT-NOW'), variant: TButtonVariant.lime, small: true)),
        TCard(eyebrow: s.supportEmptyBodyN1Eyebrow, title: s.supportEmptyBodyN1Title, text: s.supportEmptyBodyN1Text, cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: s.supportEmptyBodyN1CtaN0Label, onPressed: () => TNav.push(context, Routes.supportAddPerson), small: true)),
        TCard(eyebrow: s.supportEmptyBodyN2Eyebrow, title: s.supportEmptyBodyN2Title, text: s.supportEmptyBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.supportEmptyBodyN2CtaN0Label, onPressed: () => TNav.push(context, Routes.supportConnect), variant: TButtonVariant.secondary, small: true)),
        TEmergencyCard(text: s.supportEmptyBodyN3Text, actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: s.supportEmptyBodyN3ActionsN0Label, onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[3].actions[1]'), label: s.supportEmptyBodyN3ActionsN1Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
    );
  }
}
