// GENERATED from spec/screens/sf_home_unplug_android.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ScrollFree home · Unplug on (Android)  ·  route `/p/sf/home?state=unplug-android`  ·  flow `sf`  ·  kind `screen`
/// State: Unplug on · Android of sf_home · program sf · phase daily
/// Copy needs clinical/legal review. Android: Tether reads usage on the phone (usage access), so ScrollFree home shows measured figures instead of Apple’s native view, and the Unplug status card replaces the offer card. Shown once Unplug setup is finished on Android. Figures: yesterday and today are totals of usage categories (the same categories as ScrollFree setup); opens stay on this phone; Unplug group names never leave the phone.
///
/// Actions (generated from spec/screens/sf_home_unplug_android.json):
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
class SfHomeUnplugAndroidScreen extends StatelessWidget {
  const SfHomeUnplugAndroidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'ScrollFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: s.sfHomeUnplugAndroidBodyN0Eyebrow, children: [TBigNumber(value: s.sfHomeUnplugAndroidBodyN0ChildrenN0Value, caption: s.sfHomeUnplugAndroidBodyN0ChildrenN0Caption)]),
        TStatGrid(stats: [TStat(label: s.sfHomeUnplugAndroidBodyN1ItemsN0Label, value: s.sfHomeUnplugAndroidBodyN1ItemsN0Value, sub: s.sfHomeUnplugAndroidBodyN1ItemsN0Sub), TStat(label: s.sfHomeUnplugAndroidBodyN1ItemsN1Label, value: '14', sub: s.sfHomeUnplugAndroidBodyN1ItemsN1Sub)]),
        TBody(s.sfHomeUnplugAndroidBodyN2Text, tone: TTextTone.small),
        TCard(variant: TCardVariant.coral, title: s.sfHomeUnplugAndroidBodyN3Title, text: s.sfHomeUnplugAndroidBodyN3Text, cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: s.sfHomeUnplugAndroidBodyN3CtaN0Label, onPressed: () => TNav.push(context, Routes.sfPause), variant: TButtonVariant.rescue, small: true)),
        TCard(key: const ValueKey('a:body[4]'), variant: TCardVariant.mint, title: s.sfHomeUnplugAndroidBodyN4Title, text: s.sfHomeUnplugAndroidBodyN4Text, onTap: () => TNav.push(context, Routes.sfUnplugHome)),
        TCard(eyebrow: s.sfHomeUnplugAndroidBodyN5Eyebrow, children: [TChecklist(items: [TCheckItem(s.sfHomeUnplugAndroidBodyN5ChildrenN0ItemsN0Label, value: 'Charge your phone outside the bedroom', sub: s.sfHomeUnplugAndroidBodyN5ChildrenN0ItemsN0Sub)])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[6].rows[0]'), label: s.sfHomeUnplugAndroidBodyN6RowsN0Label, sub: s.sfHomeUnplugAndroidBodyN6RowsN0Sub, onTap: () => TNav.push(context, Routes.sfWeek)), TListRow(key: const ValueKey('a:body[6].rows[1]'), label: s.sfHomeUnplugAndroidBodyN6RowsN1Label, sub: s.sfHomeUnplugAndroidBodyN6RowsN1Sub, onTap: () => TNav.push(context, Routes.sfSlip)), TListRow(key: const ValueKey('a:body[6].rows[2]'), label: s.sfHomeUnplugAndroidBodyN6RowsN2Label, sub: s.sfHomeUnplugAndroidBodyN6RowsN2Sub, onTap: () => TNav.push(context, Routes.sfGoal)), TListRow(key: const ValueKey('a:body[6].rows[3]'), label: s.sfHomeUnplugAndroidBodyN6RowsN3Label, sub: s.sfHomeUnplugAndroidBodyN6RowsN3Sub, onTap: () => TNav.push(context, Routes.sfBuddy)), TListRow(key: const ValueKey('a:body[6].rows[4]'), label: s.sfHomeUnplugAndroidBodyN6RowsN4Label, sub: s.sfHomeUnplugAndroidBodyN6RowsN4Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'sf'))]),
      ],
    );
  }
}
