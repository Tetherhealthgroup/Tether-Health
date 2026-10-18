// GENERATED from spec/screens/sf_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ScrollFree home  ·  route `/p/sf/home`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase daily
/// 
///
/// Actions (generated from spec/screens/sf_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Pause 60 → push → sf_pause
///   • Set up → push → sf_unplug_intro
///   • This week → push → sf_week
///   • Had a long scroll? → push → sf_slip
///   • Goal & windows → push → sf_goal
///   • Buddy → push → sf_buddy
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class SfHomeScreen extends StatelessWidget {
  const SfHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'ScrollFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'Yesterday', children: [TBigNumber(value: '2h 10m', caption: 'Goal 90 min · down from 3h')]),
        TCard(variant: TCardVariant.coral, title: 'Urge to scroll?', text: 'Take 60 seconds first', cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: 'Pause 60', onPressed: () => TNav.push(context, Routes.sfPause), variant: TButtonVariant.rescue, small: true)),
        TCard(title: 'Want firmer limits?', text: 'Unplug can pause apps you choose, after limits you set. Optional.', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Set up', onPressed: () => TNav.push(context, Routes.sfUnplugIntro), variant: TButtonVariant.secondary, small: true)),
        TCard(eyebrow: 'Today’s step', children: [TChecklist(items: [TCheckItem('Charge your phone outside the bedroom', sub: 'Tonight · bedtime window 10 PM')])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: 'This week', sub: '5 of 7 phone-free nights', onTap: () => TNav.push(context, Routes.sfWeek)), TListRow(key: const ValueKey('a:body[4].rows[1]'), label: 'Had a long scroll?', sub: 'Reflect, nothing resets', onTap: () => TNav.push(context, Routes.sfSlip)), TListRow(key: const ValueKey('a:body[4].rows[2]'), label: 'Goal & windows', sub: '90 min · bedtime', onTap: () => TNav.push(context, Routes.sfGoal)), TListRow(key: const ValueKey('a:body[4].rows[3]'), label: 'Buddy', sub: 'Sam · weekly message', onTap: () => TNav.push(context, Routes.sfBuddy)), TListRow(key: const ValueKey('a:body[4].rows[4]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings))]),
      ],
    );
  }
}
