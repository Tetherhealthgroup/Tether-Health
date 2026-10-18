// GENERATED from spec/screens/sf_home_unplug.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ScrollFree home · Unplug on (iPhone)  ·  route `/p/sf/home?state=unplug`  ·  flow `sf`  ·  kind `screen`
/// State: Unplug on · iPhone of sf_home · program sf · phase daily
/// Copy needs clinical/legal review. iPhone: the native slot shows Apple’s minutes; every figure Tether stores stays the person’s own estimate and is labelled so. Android keeps the default home with real totals from readUsage.
///
/// Actions (generated from spec/screens/sf_home_unplug.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Pause 60 → push → sf_pause
///   • Unplug is on → push → sf_unplug_home
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
class SfHomeUnplugScreen extends StatelessWidget {
  const SfHomeUnplugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'ScrollFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TNativeSlot(id: 'ios.deviceActivityReport.today', label: 'Screen Time today', caption: 'Shown by Apple’s Screen Time on this phone. Tether can’t read, store or share these minutes.', height: 132.0),
        TCard(variant: TCardVariant.dark, eyebrow: 'Yesterday · your estimate', children: [TBigNumber(value: '2h 10m', caption: 'Goal 90 min · down from 3h')]),
        TCard(variant: TCardVariant.coral, title: 'Urge to scroll?', text: 'Take 60 seconds first', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Pause 60', onPressed: () => TNav.push(context, Routes.sfPause), variant: TButtonVariant.rescue, small: true)),
        TCard(key: const ValueKey('a:body[3]'), variant: TCardVariant.mint, title: 'Unplug is on', text: '2 groups · pause screen after 60 min', onTap: () => TNav.push(context, Routes.sfUnplugHome)),
        TCard(eyebrow: 'Today’s step', children: [TChecklist(items: [TCheckItem('Charge your phone outside the bedroom', sub: 'Tonight · bedtime window 10 PM')])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[5].rows[0]'), label: 'This week', sub: '5 of 7 phone-free nights', onTap: () => TNav.push(context, Routes.sfWeek)), TListRow(key: const ValueKey('a:body[5].rows[1]'), label: 'Had a long scroll?', sub: 'Reflect, nothing resets', onTap: () => TNav.push(context, Routes.sfSlip)), TListRow(key: const ValueKey('a:body[5].rows[2]'), label: 'Goal & windows', sub: '90 min · bedtime', onTap: () => TNav.push(context, Routes.sfGoal)), TListRow(key: const ValueKey('a:body[5].rows[3]'), label: 'Buddy', sub: 'Sam · weekly message', onTap: () => TNav.push(context, Routes.sfBuddy)), TListRow(key: const ValueKey('a:body[5].rows[4]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings))]),
      ],
    );
  }
}
