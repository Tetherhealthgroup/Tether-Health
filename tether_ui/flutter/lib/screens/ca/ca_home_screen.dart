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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'ClearAir', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TBoundValues(keys: const ['ca.zone_today', 'ca.zone_checked'], builder: (context, v) => TCard(variant: TCardVariant.dark, eyebrow: s.caHomeBodyN0Eyebrow, title: v.text('ca.zone_today', s.caHomeBodyN0Title), text: v.text('ca.zone_checked', s.caHomeBodyN0Text))),
        TButton(key: const ValueKey('a:body[1]'), label: s.caHomeBodyN1Label, onPressed: () => TNav.push(context, Routes.caZone), arrow: true),
        TCard(key: const ValueKey('a:body[2]'), variant: TCardVariant.urgent, title: s.caHomeBodyN2Title, text: s.caHomeBodyN2Text, onTap: () => TNav.push(context, Routes.caRed)),
        TBoundValues(keys: const ['ca.zone_counts', 'ca.plan_entered'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: s.caHomeBodyN3RowsN0Label, onTap: () => TNav.push(context, Routes.caSymptoms)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: s.caHomeBodyN3RowsN1Label, sub: v.text('ca.zone_counts', s.caHomeBodyN3RowsN1Sub), onTap: () => TNav.push(context, Routes.caProgress)), TListRow(key: const ValueKey('a:body[3].rows[2]'), label: s.caHomeBodyN3RowsN2Label, sub: v.text('ca.plan_entered', s.caHomeBodyN3RowsN2Sub), onTap: () => TNav.push(context, Routes.caPlan)), TListRow(key: const ValueKey('a:body[3].rows[3]'), label: s.caHomeBodyN3RowsN3Label, sub: s.caHomeBodyN3RowsN3Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'ca'))])),
      ],
    );
  }
}
