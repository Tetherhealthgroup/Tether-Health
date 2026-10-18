// GENERATED from spec/screens/bf_home_quitday.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// BreatheFree · quit day  ·  route `/p/bf/home?state=quit-day`  ·  flow `bf`  ·  kind `screen`
/// State: quit day of bf_home · program bf · phase milestone
/// 
///
/// Actions (generated from spec/screens/bf_home_quitday.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Rescue → sheet → rescue_pick
///   • I smoked or had a slip → push → bf_slip
///   • Morning check-in → sheet → checkin
///   • Medication center → push → bf_meds
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class BfHomeQuitdayScreen extends StatelessWidget {
  const BfHomeQuitdayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'BreatheFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TEyebrow('Quit day · Aug 28'),
        TTitle('Keep today simple.'),
        TCard(variant: TCardVariant.dark, eyebrow: 'Since your quit time', children: [TBigNumber(value: '2h 41m', caption: 'Started 7:00 AM · Pacific')]),
        TCard(variant: TCardVariant.coral, title: 'I have a craving', text: 'One tap · no typing · offline', cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: 'Rescue', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TCard(key: const ValueKey('a:body[4]'), title: 'I smoked or had a slip', text: 'Your progress will not be erased', onTap: () => TNav.push(context, Routes.bfSlip)),
        TCard(eyebrow: 'Next best step', children: [TChecklist(items: [TCheckItem('Water, then a 5-minute walk', sub: 'From your trigger plan')])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[6].rows[0]'), label: 'Morning check-in', onTap: () => TNav.sheet(context, Routes.checkin)), TListRow(key: const ValueKey('a:body[6].rows[1]'), label: 'Medication center', sub: 'Patch · taken 8:07 AM', onTap: () => TNav.push(context, Routes.bfMeds))]),
      ],
    );
  }
}
