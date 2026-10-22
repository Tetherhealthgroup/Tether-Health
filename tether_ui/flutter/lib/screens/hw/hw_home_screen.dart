// GENERATED from spec/screens/hw_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Heartwise home  ·  route `/p/hw/home`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase daily
/// 
///
/// Actions (generated from spec/screens/hw_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Log blood pressure → push → hw_log
///   • Trends → push → hw_trends
///   • Cholesterol panel → push → hw_lipids
///   • Visit summary → push → hw_summary
///   • From your health record → push → records_item
///   • My targets → push → hw_targets
///   • Program settings → push → program_settings
///   • Call 911 → call 911
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class HwHomeScreen extends StatelessWidget {
  const HwHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Heartwise', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'Last reading · 7:52 AM', children: [TBigNumber(value: '128/82', unit: 'mmHg', caption: 'Average of 2 · target below 130/80')]),
        TButton(key: const ValueKey('a:body[1]'), label: 'Log blood pressure', onPressed: () => TNav.push(context, Routes.hwLog), arrow: true),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Trends', sub: '30-day average 132/82', onTap: () => TNav.push(context, Routes.hwTrends)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Cholesterol panel', sub: 'LDL 138 · Sep 30', onTap: () => TNav.push(context, Routes.hwLipids)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Visit summary', sub: 'Preview before sharing', onTap: () => TNav.push(context, Routes.hwSummary)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'From your health record', sub: '12 readings · Patel Family Medicine (Epic)', onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: 'My targets', sub: '130/80 from Dr. Patel', onTap: () => TNav.push(context, Routes.hwTargets)), TListRow(key: const ValueKey('a:body[2].rows[5]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings, program: 'hw'))]),
        TEmergencyCard(text: 'Chest pain, pressure or trouble breathing? Call 911 now.', actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger, small: true)]),
      ],
    );
  }
}
