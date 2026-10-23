// GENERATED from spec/screens/sf_home_unplug.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ScrollFree home · Unplug on (iPhone)  ·  route `/p/sf/home?state=unplug`  ·  flow `sf`  ·  kind `screen`
/// State: Unplug on · iPhone of sf_home · program sf · phase daily
/// Copy needs clinical/legal review. iPhone: the native slot shows Apple’s minutes; every figure Tether stores stays the person’s own estimate and is labelled so. Android uses the Unplug on · Android state, with figures Tether reads on the phone.
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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'ScrollFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TNativeSlot(id: 'ios.deviceActivityReport.today', label: s.sfHomeUnplugBodyN0Label, caption: s.sfHomeUnplugBodyN0Caption, height: 132.0),
        TBoundValues(keys: const ['sf.minutes_yesterday', 'sf.goal_caption'], builder: (context, v) => TCard(variant: TCardVariant.dark, eyebrow: s.sfHomeUnplugBodyN1Eyebrow, children: [TBigNumber(value: v.text('sf.minutes_yesterday', s.sfHomeUnplugBodyN1ChildrenN0Value), caption: v.text('sf.goal_caption', s.sfHomeUnplugBodyN1ChildrenN0Caption))])),
        TCard(variant: TCardVariant.coral, title: s.sfHomeUnplugBodyN2Title, text: s.sfHomeUnplugBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.sfHomeUnplugBodyN2CtaN0Label, onPressed: () => TNav.push(context, Routes.sfPause), variant: TButtonVariant.rescue, small: true)),
        TBoundValues(keys: const ['sf.unplug.status_line'], builder: (context, v) => TCard(key: const ValueKey('a:body[3]'), variant: TCardVariant.mint, title: s.sfHomeUnplugBodyN3Title, text: v.text('sf.unplug.status_line', s.sfHomeUnplugBodyN3Text), onTap: () => TNav.push(context, Routes.sfUnplugHome))),
        TCard(eyebrow: s.sfHomeUnplugBodyN4Eyebrow, children: [TChecklist(items: [TCheckItem(s.sfHomeUnplugBodyN4ChildrenN0ItemsN0Label, value: 'Charge your phone outside the bedroom', sub: s.sfHomeUnplugBodyN4ChildrenN0ItemsN0Sub)])]),
        TBoundValues(keys: const ['sf.phone_free_nights_summary', 'sf.goal_summary', 'sf.buddy.summary'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[5].rows[0]'), label: s.sfHomeUnplugBodyN5RowsN0Label, sub: v.text('sf.phone_free_nights_summary', s.sfHomeUnplugBodyN5RowsN0Sub), onTap: () => TNav.push(context, Routes.sfWeek)), TListRow(key: const ValueKey('a:body[5].rows[1]'), label: s.sfHomeUnplugBodyN5RowsN1Label, sub: s.sfHomeUnplugBodyN5RowsN1Sub, onTap: () => TNav.push(context, Routes.sfSlip)), TListRow(key: const ValueKey('a:body[5].rows[2]'), label: s.sfHomeUnplugBodyN5RowsN2Label, sub: v.text('sf.goal_summary', s.sfHomeUnplugBodyN5RowsN2Sub), onTap: () => TNav.push(context, Routes.sfGoal)), TListRow(key: const ValueKey('a:body[5].rows[3]'), label: s.sfHomeUnplugBodyN5RowsN3Label, sub: v.text('sf.buddy.summary', s.sfHomeUnplugBodyN5RowsN3Sub), onTap: () => TNav.push(context, Routes.sfBuddy)), TListRow(key: const ValueKey('a:body[5].rows[4]'), label: s.sfHomeUnplugBodyN5RowsN4Label, sub: s.sfHomeUnplugBodyN5RowsN4Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'sf'))])),
      ],
    );
  }
}
