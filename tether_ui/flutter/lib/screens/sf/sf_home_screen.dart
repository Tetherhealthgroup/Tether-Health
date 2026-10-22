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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'ScrollFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: s.sfHomeBodyN0Eyebrow, children: [TBigNumber(value: s.sfHomeBodyN0ChildrenN0Value, caption: s.sfHomeBodyN0ChildrenN0Caption)]),
        TCard(variant: TCardVariant.coral, title: s.sfHomeBodyN1Title, text: s.sfHomeBodyN1Text, cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: s.sfHomeBodyN1CtaN0Label, onPressed: () => TNav.push(context, Routes.sfPause), variant: TButtonVariant.rescue, small: true)),
        TCard(title: s.sfHomeBodyN2Title, text: s.sfHomeBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.sfHomeBodyN2CtaN0Label, onPressed: () => TNav.push(context, Routes.sfUnplugIntro), variant: TButtonVariant.secondary, small: true)),
        TCard(eyebrow: s.sfHomeBodyN3Eyebrow, children: [TChecklist(items: [TCheckItem(s.sfHomeBodyN3ChildrenN0ItemsN0Label, value: 'Charge your phone outside the bedroom', sub: s.sfHomeBodyN3ChildrenN0ItemsN0Sub)])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: s.sfHomeBodyN4RowsN0Label, sub: s.sfHomeBodyN4RowsN0Sub, onTap: () => TNav.push(context, Routes.sfWeek)), TListRow(key: const ValueKey('a:body[4].rows[1]'), label: s.sfHomeBodyN4RowsN1Label, sub: s.sfHomeBodyN4RowsN1Sub, onTap: () => TNav.push(context, Routes.sfSlip)), TListRow(key: const ValueKey('a:body[4].rows[2]'), label: s.sfHomeBodyN4RowsN2Label, sub: s.sfHomeBodyN4RowsN2Sub, onTap: () => TNav.push(context, Routes.sfGoal)), TListRow(key: const ValueKey('a:body[4].rows[3]'), label: s.sfHomeBodyN4RowsN3Label, sub: s.sfHomeBodyN4RowsN3Sub, onTap: () => TNav.push(context, Routes.sfBuddy)), TListRow(key: const ValueKey('a:body[4].rows[4]'), label: s.sfHomeBodyN4RowsN4Label, sub: s.sfHomeBodyN4RowsN4Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'sf'))]),
      ],
    );
  }
}
