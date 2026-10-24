// GENERATED from spec/screens/today_empty.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Today · nothing in focus  ·  route `/today?state=empty`  ·  flow `today`  ·  kind `screen`
/// State: empty of today · phase daily
/// 
///
/// Actions (generated from spec/screens/today_empty.json):
///   • Avatar · Account → push → account
///   • Choose a focus program → push → account_programs
///   • Browse lessons → tab → learn
///   • Support → tab → support
///   • Tab · Plans → tab → plans
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class TodayEmptyScreen extends StatelessWidget {
  const TodayEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.todayEmptyHeaderTitle, left: THeaderLeft.logo, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'today',
      children: [
        TBoundValues(keys: const ['today.greeting'], place: TExamplePlace.inline, builder: (context, v) => TTitle(v.text('today.greeting', s.todayEmptyBodyN0Text))),
        TIllustration(glyph: '+'),
        TTitle(s.todayEmptyBodyN2Text, center: true),
        TBody(s.todayEmptyBodyN3Text, tone: TTextTone.muted, center: true),
        TButton(key: const ValueKey('a:body[4]'), label: s.todayEmptyBodyN4Label, onPressed: () => TNav.push(context, Routes.accountPrograms), arrow: true),
        TButton(key: const ValueKey('a:body[5]'), label: s.todayEmptyBodyN5Label, onPressed: () => TNav.tab(context, Routes.learn), variant: TButtonVariant.secondary),
        TCard(title: s.todayEmptyBodyN6Title, text: s.todayEmptyBodyN6Text, cta: TButton(key: const ValueKey('a:body[6].cta[0]'), label: s.todayEmptyBodyN6CtaN0Label, onPressed: () => TNav.tab(context, Routes.support), variant: TButtonVariant.secondary, small: true)),
      ],
    );
  }
}
