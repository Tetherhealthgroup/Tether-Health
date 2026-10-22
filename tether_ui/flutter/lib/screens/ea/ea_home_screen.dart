// GENERATED from spec/screens/ea_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Ease home  ·  route `/p/ea/home`  ·  flow `ea`  ·  kind `screen`
/// Default state · program ea · phase daily
/// 
///
/// Actions (generated from spec/screens/ea_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Start → push → ea_mood
///   • My safety plan → push → ea_plan
///   • Check-back → push → ea_checkback
///   • Find a professional → push → ea_result
///   • Program settings → push → program_settings
///   • Sleep and mood: 3 small changes → push → learn_lesson
///   • Call or text 988 → push → crisis
///   • Call 911 → call 911
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class EaHomeScreen extends StatelessWidget {
  const EaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Ease', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'How are you right now?', title: '30-second mood check-in', cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: 'Start', onPressed: () => TNav.push(context, Routes.eaMood), variant: TButtonVariant.lime, small: true)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'My safety plan', sub: 'Updated Oct 2', onTap: () => TNav.push(context, Routes.eaPlan)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'Check-back', sub: 'In 6 days', onTap: () => TNav.push(context, Routes.eaCheckback)), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: 'Find a professional', onTap: () => TNav.push(context, Routes.eaResult)), TListRow(key: const ValueKey('a:body[1].rows[3]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings, program: 'ea'))]),
        TCard(key: const ValueKey('a:body[2]'), tag: 'ea', title: 'Sleep and mood: 3 small changes', text: '5 min', onTap: () => TNav.push(context, Routes.learnLesson)),
        TEmergencyCard(text: 'Thoughts of harming yourself? Call or text 988. Emergency: 911.', actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: 'Call or text 988', onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[3].actions[1]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
    );
  }
}
