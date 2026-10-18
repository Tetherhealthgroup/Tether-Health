// GENERATED from spec/screens/today_loading.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Today · loading  ·  route `/today?state=loading`  ·  flow `today`  ·  kind `screen`
/// State: loading of today · phase daily
/// 
///
/// Actions (generated from spec/screens/today_loading.json):
///   • Avatar · Account → push → account
///   • Rescue → sheet → rescue_pick
///   • Tab · Plans → tab → plans
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class TodayLoadingScreen extends StatelessWidget {
  const TodayLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Today', left: THeaderLeft.logo, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'today',
      children: [
        TSkeleton(lines: 1),
        TCard(variant: TCardVariant.coral, title: 'Craving or urge?', text: 'One tap · no typing', cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: 'Rescue', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TSkeleton(lines: 3),
        TSkeleton(lines: 2),
        TBody('The rest of Today is still loading.', tone: TTextTone.small),
      ],
    );
  }
}
