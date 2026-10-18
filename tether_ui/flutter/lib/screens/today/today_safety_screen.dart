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
    return TScreen(
      header: THeader(title: 'Today', left: THeaderLeft.logo, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'today',
      children: [
        TBanner(kind: TBannerKind.urgent, text: 'Your last blood pressure was in the crisis range.'),
        TCard(variant: TCardVariant.urgent, title: 'Any chest pain, shortness of breath, weakness, vision change or trouble speaking?', text: 'Heartwise · from your 8:10 AM reading', children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[1].children[0].items[0]'), label: 'Yes · call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[1].children[0].items[1]'), label: 'No symptoms', onPressed: () => TNav.push(context, Routes.hwRecheck), variant: TButtonVariant.secondary, small: true)])]),
        TBody('Other steps are paused until you answer. Safety always comes first.', tone: TTextTone.small),
        TCard(eyebrow: 'Today · paused', children: [TChecklist(items: [TCheckItem('Stock gum, water or snacks'), TCheckItem('Charge phone outside the bedroom')])]),
      ],
    );
  }
}
