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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Nourish', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TBoundValues(keys: const ['nu.habit_week', 'nu.habit_name', 'nu.habit_progress'], builder: (context, v) => TCard(eyebrow: v.text('nu.habit_week', s.nuHomeBodyN0Eyebrow), title: v.text('nu.habit_name', s.nuHomeBodyN0Title), text: v.text('nu.habit_progress', s.nuHomeBodyN0Text), cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: s.nuHomeBodyN0CtaN0Label, onPressed: () => TNav.toast(context, s.nuHomeBodyN0CtaN0ActionValue), small: true), children: [TSteps(n: 3, total: 5)])),
        TCard(variant: TCardVariant.mint, eyebrow: s.nuHomeBodyN1Eyebrow, title: s.nuHomeBodyN1Title),
        TCard(key: const ValueKey('a:body[2]'), eyebrow: s.nuHomeBodyN2Eyebrow, title: s.nuHomeBodyN2Title, text: s.nuHomeBodyN2Text, onTap: () => TNav.push(context, Routes.learnLesson)),
        TBoundValues(keys: const ['nu.milestone_due'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: s.nuHomeBodyN3RowsN0Label, sub: s.nuHomeBodyN3RowsN0Sub, onTap: () => TNav.push(context, Routes.nuReset)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: s.nuHomeBodyN3RowsN1Label, sub: v.text('nu.milestone_due', s.nuHomeBodyN3RowsN1Sub), onTap: () => TNav.push(context, Routes.nuWeek4)), TListRow(key: const ValueKey('a:body[3].rows[2]'), label: s.nuHomeBodyN3RowsN2Label, onTap: () => TNav.push(context, Routes.nuHabit)), TListRow(key: const ValueKey('a:body[3].rows[3]'), label: s.nuHomeBodyN3RowsN3Label, sub: s.nuHomeBodyN3RowsN3Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'nu'))])),
      ],
    );
  }
}
