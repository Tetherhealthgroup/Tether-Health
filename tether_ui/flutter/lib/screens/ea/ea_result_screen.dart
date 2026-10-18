// GENERATED from spec/screens/ea_result.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Screener result  ·  route `/p/ea/result`  ·  flow `ea`  ·  kind `screen`
/// Default state · program ea · phase onboarding
/// 
///
/// Actions (generated from spec/screens/ea_result.json):
///   • Back → back
///   • Find a therapist near me → external https://findtreatment.gov
///   • Talk to my primary care doctor → push → support_message_care
///   • Not now → push → ea_plan
///   • Call or text 988 → push → crisis
///   • Call 911 → call 911
/// API: —
class EaResultScreen extends StatelessWidget {
  const EaResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your answers', pill: 'Not a diagnosis'),
      children: [
        TTitle('Talking to someone could help.'),
        TCard(variant: TCardVariant.mint, text: 'Your answers suggest you’ve been carrying a lot lately. A doctor, counselor or therapist can help figure out what would make the biggest difference.'),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Find a therapist near me', sub: 'In-network filters', onTap: () => TNav.external(context, 'https://findtreatment.gov')), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Talk to my primary care doctor', sub: 'We’ll help you prepare', onTap: () => TNav.push(context, Routes.supportMessageCare)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Not now', sub: 'Keep using Ease tools', onTap: () => TNav.push(context, Routes.eaPlan))]),
        TEmergencyCard(text: 'Thoughts of harming yourself? Call or text 988. Emergency: 911.', actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: 'Call or text 988', onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[3].actions[1]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
    );
  }
}
