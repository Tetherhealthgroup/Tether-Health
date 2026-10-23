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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'BreatheFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TBoundValues(keys: const ['bf.quit_day_heading'], place: TExamplePlace.inline, builder: (context, v) => TEyebrow(v.text('bf.quit_day_heading', s.bfHomeQuitdayBodyN0Text))),
        TTitle(s.bfHomeQuitdayBodyN1Text),
        TBoundValues(keys: const ['bf.time_since_quit', 'bf.quit_time_caption'], builder: (context, v) => TCard(variant: TCardVariant.dark, eyebrow: s.bfHomeQuitdayBodyN2Eyebrow, children: [TBigNumber(value: v.text('bf.time_since_quit', s.bfHomeQuitdayBodyN2ChildrenN0Value), caption: v.text('bf.quit_time_caption', s.bfHomeQuitdayBodyN2ChildrenN0Caption))])),
        TCard(variant: TCardVariant.coral, title: s.bfHomeQuitdayBodyN3Title, text: s.bfHomeQuitdayBodyN3Text, cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: s.bfHomeQuitdayBodyN3CtaN0Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TCard(key: const ValueKey('a:body[4]'), title: s.bfHomeQuitdayBodyN4Title, text: s.bfHomeQuitdayBodyN4Text, onTap: () => TNav.push(context, Routes.bfSlip)),
        TCard(eyebrow: s.bfHomeQuitdayBodyN5Eyebrow, children: [TChecklist(items: [TCheckItem(s.bfHomeQuitdayBodyN5ChildrenN0ItemsN0Label, value: 'Water, then a 5-minute walk', sub: s.bfHomeQuitdayBodyN5ChildrenN0ItemsN0Sub)])]),
        TBoundValues(keys: const ['bf.meds.today_summary'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[6].rows[0]'), label: s.bfHomeQuitdayBodyN6RowsN0Label, onTap: () => TNav.sheet(context, Routes.checkin)), TListRow(key: const ValueKey('a:body[6].rows[1]'), label: s.bfHomeQuitdayBodyN6RowsN1Label, sub: v.text('bf.meds.today_summary', s.bfHomeQuitdayBodyN6RowsN1Sub), onTap: () => TNav.push(context, Routes.bfMeds))])),
      ],
    );
  }
}
