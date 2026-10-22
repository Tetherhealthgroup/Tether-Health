// GENERATED from spec/screens/today_safety.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Today · safety pinned  ·  route `/today?state=safety`  ·  flow `today`  ·  kind `screen`
/// State: safety of today · phase rescue
/// 
///
/// Actions (generated from spec/screens/today_safety.json):
///   • Avatar · Account → push → account
///   • Yes · call 911 → call 911
///   • No symptoms → push → hw_recheck
///   • Tab · Plans → tab → plans
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class TodaySafetyScreen extends StatelessWidget {
  const TodaySafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.todaySafetyHeaderTitle, left: THeaderLeft.logo, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'today',
      children: [
        TBanner(kind: TBannerKind.urgent, text: s.todaySafetyBodyN0Text),
        TCard(variant: TCardVariant.urgent, title: s.todaySafetyBodyN1Title, text: s.todaySafetyBodyN1Text, children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[1].children[0].items[0]'), label: s.todaySafetyBodyN1ChildrenN0ItemsN0Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[1].children[0].items[1]'), label: s.todaySafetyBodyN1ChildrenN0ItemsN1Label, onPressed: () => TNav.push(context, Routes.hwRecheck), variant: TButtonVariant.secondary, small: true)])]),
        TBody(s.todaySafetyBodyN2Text, tone: TTextTone.small),
        TCard(eyebrow: s.todaySafetyBodyN3Eyebrow, children: [TChecklist(items: [TCheckItem(s.todaySafetyBodyN3ChildrenN0ItemsN0Label, value: 'Stock gum, water or snacks'), TCheckItem(s.todaySafetyBodyN3ChildrenN0ItemsN1Label, value: 'Charge phone outside the bedroom')])]),
      ],
    );
  }
}
