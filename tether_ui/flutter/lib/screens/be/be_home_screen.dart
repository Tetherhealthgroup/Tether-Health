// GENERATED from spec/screens/be_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Beacon home  ·  route `/p/be/home`  ·  flow `be`  ·  kind `screen`
/// Default state · program be · phase daily
/// 
///
/// Actions (generated from spec/screens/be_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Quitting smoking → push → bf_home
///   • Monthly skin self-check → push → learn_lesson
///   • Ask about genetic counseling → push → support_message_care
///   • Open Checkup → push → ck_list
///   • Change my journey stage → push → be_q1
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class BeHomeScreen extends StatelessWidget {
  const BeHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Beacon', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TTitle('Three steps that lower risk'),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'Quitting smoking', sub: 'In progress with BreatheFree', lead: TLead.program('bf'), pill: 'Active', onTap: () => TNav.push(context, Routes.bfHome)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'Monthly skin self-check', sub: 'Guide with photos', onTap: () => TNav.push(context, Routes.learnLesson)), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: 'Ask about genetic counseling', sub: 'Because of family history', onTap: () => TNav.push(context, Routes.supportMessageCare))]),
        TCard(title: 'Screenings come from Checkup', text: 'Mammogram due · colorectal due', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Open Checkup', onPressed: () => TNav.push(context, Routes.ckList), variant: TButtonVariant.secondary, small: true)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Change my journey stage', onTap: () => TNav.push(context, Routes.beQ1)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings, program: 'be'))]),
      ],
    );
  }
}
