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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.todayHeaderTitle, left: THeaderLeft.logo, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'today',
      children: [
        TBoundValues(keys: const ['today.date'], place: TExamplePlace.inline, builder: (context, v) => TEyebrow(v.text('today.date', s.todayBodyN0Text))),
        TBoundValues(keys: const ['today.greeting'], place: TExamplePlace.inline, builder: (context, v) => TTitle(v.text('today.greeting', s.todayBodyN1Text))),
        TChips(fieldKey: 'today.value', options: ['All', 'BreatheFree', 'ScrollFree'], labels: [s.todayBodyN2OptionsN0, 'BreatheFree', 'ScrollFree'], selected: ['All'], multi: false, dots: {'BreatheFree': TColors.program('bf'), 'ScrollFree': TColors.program('sf')}),
        TCard(variant: TCardVariant.coral, title: s.todayBodyN3Title, text: s.todayBodyN3Text, cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: s.todayBodyN3CtaN0Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TBoundValues(keys: const ['today.steps_heading'], builder: (context, v) => TCard(eyebrow: v.text('today.steps_heading', s.todayBodyN4Eyebrow), children: [TChecklist(items: [TCheckItem(s.todayBodyN4ChildrenN0ItemsN0Label, value: 'Stock gum, water or snacks', sub: s.todayBodyN4ChildrenN0ItemsN0Sub, done: true), TCheckItem(s.todayBodyN4ChildrenN0ItemsN1Label, value: 'Charge your phone outside the bedroom', sub: s.todayBodyN4ChildrenN0ItemsN1Sub)])])),
        TCard(variant: TCardVariant.dark, eyebrow: s.todayBodyN5Eyebrow, title: s.todayBodyN5Title, cta: TButton(key: const ValueKey('a:body[5].cta[0]'), label: s.todayBodyN5CtaN0Label, onPressed: () => TNav.sheet(context, Routes.checkin), variant: TButtonVariant.lime, small: true)),
        TBoundValues(keys: const ['bf.days_to_quit_day', 'bf.quit_date_short', 'sf.minutes_yesterday', 'sf.goal_short'], builder: (context, v) => TStatGrid(stats: [TStat(label: s.todayBodyN6ItemsN0Label, value: v.text('bf.days_to_quit_day', s.todayBodyN6ItemsN0Value), sub: v.text('bf.quit_date_short', s.todayBodyN6ItemsN0Sub), program: 'bf'), TStat(label: s.todayBodyN6ItemsN1Label, value: v.text('sf.minutes_yesterday', s.todayBodyN6ItemsN1Value), sub: v.text('sf.goal_short', s.todayBodyN6ItemsN1Sub), program: 'sf')])),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[7].rows[0]'), label: s.todayBodyN7RowsN0Label, sub: s.todayBodyN7RowsN0Sub, lead: TLead.program('bf'), onTap: () => TNav.push(context, Routes.bfHome)), TListRow(key: const ValueKey('a:body[7].rows[1]'), label: s.todayBodyN7RowsN1Label, sub: s.todayBodyN7RowsN1Sub, lead: TLead.program('sf'), onTap: () => TNav.push(context, Routes.sfHome))]),
        TCard(key: const ValueKey('a:body[8]'), variant: TCardVariant.mint, tag: 'ca', tagExtra: s.todayBodyN8TagExtra, title: s.todayBodyN8Title, text: s.todayBodyN8Text, onTap: () => TNav.push(context, Routes.learnLesson, argument: 'ca.lungs-recover')),
      ],
    );
  }
}
