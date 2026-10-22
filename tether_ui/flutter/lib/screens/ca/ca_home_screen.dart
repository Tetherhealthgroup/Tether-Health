// GENERATED from spec/screens/ca_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ClearAir home  ·  route `/p/ca/home`  ·  flow `ca`  ·  kind `screen`
/// Default state · program ca · phase daily
/// 
///
/// Actions (generated from spec/screens/ca_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Check my zone → push → ca_zone
///   • Red-zone plan → push → ca_red
///   • Log symptoms → push → ca_symptoms
///   • Progress → push → ca_progress
///   • My action plan → push → ca_plan
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class CaHomeScreen extends StatelessWidget {
  const CaHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'ClearAir', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'Today’s zone', title: 'Green · 410 L/min', text: 'Checked 7:40 AM · from your plan'),
        TButton(key: const ValueKey('a:body[1]'), label: 'Check my zone', onPressed: () => TNav.push(context, Routes.caZone), arrow: true),
        TCard(key: const ValueKey('a:body[2]'), variant: TCardVariant.urgent, title: 'Red-zone plan', text: 'Open it fast', onTap: () => TNav.push(context, Routes.caRed)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Log symptoms', onTap: () => TNav.push(context, Routes.caSymptoms)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'Progress', sub: '10 green · 2 yellow · 0 red', onTap: () => TNav.push(context, Routes.caProgress)), TListRow(key: const ValueKey('a:body[3].rows[2]'), label: 'My action plan', sub: 'Entered Sep 3', onTap: () => TNav.push(context, Routes.caPlan)), TListRow(key: const ValueKey('a:body[3].rows[3]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings, program: 'ca'))]),
      ],
    );
  }
}
