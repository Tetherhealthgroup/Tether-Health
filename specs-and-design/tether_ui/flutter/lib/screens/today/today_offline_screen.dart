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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.todayOfflineHeaderTitle, left: THeaderLeft.logo, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'today',
      children: [
        TBoundValues(keys: const ['today.offline_banner'], builder: (context, v) => TBanner(kind: TBannerKind.offline, text: v.text('today.offline_banner', s.todayOfflineBodyN0Text))),
        TBoundValues(keys: const ['today.greeting'], place: TExamplePlace.inline, builder: (context, v) => TTitle(v.text('today.greeting', s.todayOfflineBodyN1Text))),
        TCard(variant: TCardVariant.coral, title: s.todayOfflineBodyN2Title, text: s.todayOfflineBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.todayOfflineBodyN2CtaN0Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TCard(eyebrow: s.todayOfflineBodyN3Eyebrow, children: [TChecklist(items: [TCheckItem(s.todayOfflineBodyN3ChildrenN0ItemsN0Label, value: 'Stock gum, water or snacks', sub: s.todayOfflineBodyN3ChildrenN0ItemsN0Sub, done: true)])]),
        TBody(s.todayOfflineBodyN4Text, tone: TTextTone.small),
      ],
    );
  }
}
