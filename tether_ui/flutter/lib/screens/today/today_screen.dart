// GENERATED from spec/screens/today.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Today  ·  route `/today`  ·  flow `today`  ·  kind `screen`
/// Default state · phase daily
/// Composed from every Focus enrolment. If a program safety rule fires, its card is pinned first (see Safety state).
///
/// Actions (generated from spec/screens/today.json):
///   • Avatar · Account → push → account
///   • Rescue → sheet → rescue_pick
///   • Start → sheet → checkin
///   • BreatheFree home → push → bf_home
///   • ScrollFree home → push → sf_home
///   • How your lungs recover after you quit → push → learn_lesson
///   • Tab · Plans → tab → plans
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: GET /v1/today
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Today', left: THeaderLeft.logo, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'today',
      children: [
        TEyebrow('Friday, August 21'),
        TTitle('Good morning, Alex.'),
        TChips(fieldKey: 'today.value', options: ['All', 'BreatheFree', 'ScrollFree'], selected: ['All'], multi: false, dots: {'BreatheFree': TColors.program('bf'), 'ScrollFree': TColors.program('sf')}),
        TCard(variant: TCardVariant.coral, title: 'Craving or urge to scroll?', text: 'Help for the next few minutes · works offline', cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: 'Rescue', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TCard(eyebrow: 'Today · 2 small steps', children: [TChecklist(items: [TCheckItem('Stock gum, water or snacks', sub: 'BreatheFree · 3 min', done: true), TCheckItem('Charge your phone outside the bedroom', sub: 'ScrollFree · tonight')])]),
        TCard(variant: TCardVariant.dark, eyebrow: 'Check-in · about 90 sec', title: 'Covers both programs', cta: TButton(key: const ValueKey('a:body[5].cta[0]'), label: 'Start', onPressed: () => TNav.sheet(context, Routes.checkin), variant: TButtonVariant.lime, small: true)),
        TStatGrid(stats: [TStat(label: 'Quit day', value: '7 days', sub: 'Fri, Aug 28', program: 'bf'), TStat(label: 'Yesterday', value: '2h 10m', sub: 'goal 90 min', program: 'sf')]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[7].rows[0]'), label: 'BreatheFree home', sub: 'Plan, medicines, progress', lead: TLead.program('bf'), onTap: () => TNav.push(context, Routes.bfHome)), TListRow(key: const ValueKey('a:body[7].rows[1]'), label: 'ScrollFree home', sub: 'Goal, Pause 60, week', lead: TLead.program('sf'), onTap: () => TNav.push(context, Routes.sfHome))]),
        TCard(key: const ValueKey('a:body[8]'), variant: TCardVariant.mint, tag: 'ca', tagExtra: 'Learn only', title: 'How your lungs recover after you quit', text: '4 min read', onTap: () => TNav.push(context, Routes.learnLesson)),
      ],
    );
  }
}
