// GENERATED from spec/screens/today_offline.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Today · offline  ·  route `/today?state=offline`  ·  flow `today`  ·  kind `screen`
/// State: offline of today · phase daily
/// 
///
/// Actions (generated from spec/screens/today_offline.json):
///   • Avatar · Account → push → account
///   • Rescue → sheet → rescue_pick
///   • Tab · Plans → tab → plans
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class TodayOfflineScreen extends StatelessWidget {
  const TodayOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Today', left: THeaderLeft.logo, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'today',
      children: [
        TBanner(kind: TBannerKind.offline, text: 'Offline · 3 entries will sync when you reconnect.'),
        TTitle('Good morning, Alex.'),
        TCard(variant: TCardVariant.coral, title: 'Craving or urge?', text: 'Works offline', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Rescue', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TCard(eyebrow: 'Today', children: [TChecklist(items: [TCheckItem('Stock gum, water or snacks', sub: 'Saved on this phone', done: true)])]),
        TBody('Lessons not downloaded load when you’re back online.', tone: TTextTone.small),
      ],
    );
  }
}
