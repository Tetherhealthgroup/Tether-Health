// GENERATED from spec/screens/nu_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Nourish home  ·  route `/p/nu/home`  ·  flow `nu`  ·  kind `screen`
/// Default state · program nu · phase daily
/// 
///
/// Actions (generated from spec/screens/nu_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Done today → toast “Nice. 4 of 5 nights.”
///   • Bean and veggie tacos → push → learn_lesson
///   • Busy week? → push → nu_reset
///   • Week 4 milestone → push → nu_week4
///   • Change habit → push → nu_habit
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class NuHomeScreen extends StatelessWidget {
  const NuHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Nourish', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(eyebrow: 'Habit · week 2', title: 'Add a vegetable to dinner', text: '3 of 5 nights', cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: 'Done today', onPressed: () => TNav.toast(context, 'Nice. 4 of 5 nights.'), small: true), children: [TSteps(n: 3, total: 5)]),
        TCard(variant: TCardVariant.mint, eyebrow: 'Tip', title: 'Frozen vegetables count, and are often cheaper.'),
        TCard(key: const ValueKey('a:body[2]'), eyebrow: 'Quick recipe · 15 min', title: 'Bean and veggie tacos', text: 'Under \$2 a serving', onTap: () => TNav.push(context, Routes.learnLesson)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Busy week?', sub: 'Reset without guilt', onTap: () => TNav.push(context, Routes.nuReset)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'Week 4 milestone', sub: 'In 2 weeks', onTap: () => TNav.push(context, Routes.nuWeek4)), TListRow(key: const ValueKey('a:body[3].rows[2]'), label: 'Change habit', onTap: () => TNav.push(context, Routes.nuHabit)), TListRow(key: const ValueKey('a:body[3].rows[3]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings, program: 'nu'))]),
      ],
    );
  }
}
