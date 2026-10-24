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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Beacon', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TTitle(s.beHomeBodyN0Text),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: s.beHomeBodyN1RowsN0Label, sub: s.beHomeBodyN1RowsN0Sub, lead: TLead.program('bf'), pill: s.beHomeBodyN1RowsN0Pill, onTap: () => TNav.push(context, Routes.bfHome)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: s.beHomeBodyN1RowsN1Label, sub: s.beHomeBodyN1RowsN1Sub, onTap: () => TNav.push(context, Routes.learnLesson, argument: 'be.skin-self-check')), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: s.beHomeBodyN1RowsN2Label, sub: s.beHomeBodyN1RowsN2Sub, onTap: () => TNav.push(context, Routes.supportMessageCare))]),
        TCard(title: s.beHomeBodyN2Title, text: s.beHomeBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.beHomeBodyN2CtaN0Label, onPressed: () => TNav.push(context, Routes.ckList), variant: TButtonVariant.secondary, small: true)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: s.beHomeBodyN3RowsN0Label, onTap: () => TNav.push(context, Routes.beQ1)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: s.beHomeBodyN3RowsN1Label, sub: s.beHomeBodyN3RowsN1Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'be'))]),
      ],
    );
  }
}
