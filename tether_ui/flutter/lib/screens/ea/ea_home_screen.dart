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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Ease', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: s.eaHomeBodyN0Eyebrow, title: s.eaHomeBodyN0Title, cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: s.eaHomeBodyN0CtaN0Label, onPressed: () => TNav.push(context, Routes.eaMood), variant: TButtonVariant.lime, small: true)),
        TBoundValues(keys: const ['ea.plan_updated', 'ea.check_back_due'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: s.eaHomeBodyN1RowsN0Label, sub: v.text('ea.plan_updated', s.eaHomeBodyN1RowsN0Sub), onTap: () => TNav.push(context, Routes.eaPlan)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: s.eaHomeBodyN1RowsN1Label, sub: v.text('ea.check_back_due', s.eaHomeBodyN1RowsN1Sub), onTap: () => TNav.push(context, Routes.eaCheckback)), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: s.eaHomeBodyN1RowsN2Label, onTap: () => TNav.push(context, Routes.eaResult)), TListRow(key: const ValueKey('a:body[1].rows[3]'), label: s.eaHomeBodyN1RowsN3Label, sub: s.eaHomeBodyN1RowsN3Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'ea'))])),
        TCard(key: const ValueKey('a:body[2]'), tag: 'ea', title: s.eaHomeBodyN2Title, text: s.eaHomeBodyN2Text, onTap: () => TNav.push(context, Routes.learnLesson)),
        TEmergencyCard(text: s.eaHomeBodyN3Text, actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: s.eaHomeBodyN3ActionsN0Label, onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[3].actions[1]'), label: s.eaHomeBodyN3ActionsN1Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
    );
  }
}
