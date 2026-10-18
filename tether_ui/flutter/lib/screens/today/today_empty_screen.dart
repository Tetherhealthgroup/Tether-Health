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
    return TScreen(
      header: THeader(title: 'Today', left: THeaderLeft.logo, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'today',
      children: [
        TTitle('Good evening, Alex.'),
        TIllustration(glyph: '+'),
        TTitle('Nothing in focus right now', center: true),
        TBody('Your programs are paused or in Learn only. Pick one for daily support, or keep exploring.', tone: TTextTone.muted, center: true),
        TButton(key: const ValueKey('a:body[4]'), label: 'Choose a focus program', onPressed: () => TNav.push(context, Routes.accountPrograms), arrow: true),
        TButton(key: const ValueKey('a:body[5]'), label: 'Browse lessons', onPressed: () => TNav.tab(context, Routes.learn), variant: TButtonVariant.secondary),
        TCard(title: 'Need help now?', text: 'Rescue and Support still work', cta: TButton(key: const ValueKey('a:body[6].cta[0]'), label: 'Support', onPressed: () => TNav.tab(context, Routes.support), variant: TButtonVariant.secondary, small: true)),
      ],
    );
  }
}
