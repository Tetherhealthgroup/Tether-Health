// GENERATED from spec/screens/st_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Steady home  ·  route `/p/st/home`  ·  flow `st`  ·  kind `screen`
/// Default state · program st · phase daily
/// 
///
/// Actions (generated from spec/screens/st_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Log a reading → push → st_log
///   • Meal energy reset → push → st_reset
///   • Patterns → push → st_patterns
///   • A1C history → push → st_a1c
///   • My range & low plan → push → st_range
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class StHomeScreen extends StatelessWidget {
  const StHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Steady', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'Last reading · 2 h after lunch', children: [TBigNumber(value: '142', unit: 'mg/dL', caption: 'Within your after-meal range (below 180)')]),
        TButton(key: const ValueKey('a:body[1]'), label: 'Log a reading', onPressed: () => TNav.push(context, Routes.stLog), arrow: true),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Meal energy reset', sub: '3 minutes', onTap: () => TNav.push(context, Routes.stReset)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Patterns', sub: '71% in range · 14 days', onTap: () => TNav.push(context, Routes.stPatterns)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'A1C history', sub: '7.4% · Oct 1', onTap: () => TNav.push(context, Routes.stA1c)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'My range & low plan', onTap: () => TNav.push(context, Routes.stRange)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings, program: 'st'))]),
        TCard(variant: TCardVariant.mint, text: 'Steady never counts calories. A high reading is information, not failure.'),
      ],
    );
  }
}
