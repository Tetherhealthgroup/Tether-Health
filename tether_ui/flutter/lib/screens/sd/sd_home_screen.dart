// GENERATED from spec/screens/sd_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Stride home  ·  route `/p/sd/home`  ·  flow `sd`  ·  kind `screen`
/// Default state · program sd · phase daily
/// 
///
/// Actions (generated from spec/screens/sd_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Start → push → sd_session
///   • I fell → push → sd_fell
///   • Home safety checklist → push → sd_safety
///   • Caregiver access → push → sd_caregiver
///   • Movement plan → push → sd_plan
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class SdHomeScreen extends StatelessWidget {
  const SdHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Stride', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'Today · Wednesday', title: 'Strength (chair) · 10 min', cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: 'Start', onPressed: () => TNav.push(context, Routes.sdSession), variant: TButtonVariant.lime, small: true)),
        TCard(key: const ValueKey('a:body[1]'), variant: TCardVariant.urgent, title: 'I fell', text: 'Get help or log a fall', onTap: () => TNav.push(context, Routes.sdFell)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Home safety checklist', sub: '2 of 5 done', onTap: () => TNav.push(context, Routes.sdSafety)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Caregiver access', sub: 'Rosa · Stride only', onTap: () => TNav.push(context, Routes.sdCaregiver)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Movement plan', sub: '3 sessions a week', onTap: () => TNav.push(context, Routes.sdPlan)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings, program: 'sd'))]),
        TStatGrid(stats: [TStat(label: 'This week', value: '1 of 3', sub: 'sessions'), TStat(label: 'Falls logged', value: '0', sub: 'last 30 days')]),
      ],
    );
  }
}
