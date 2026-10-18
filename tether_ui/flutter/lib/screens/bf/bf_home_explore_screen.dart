// GENERATED from spec/screens/bf_home_explore.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// BreatheFree · explore  ·  route `/p/bf/home?state=explore`  ·  flow `bf`  ·  kind `screen`
/// State: explore of bf_home · program bf · phase daily
/// 
///
/// Actions (generated from spec/screens/bf_home_explore.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Rescue → sheet → rescue_pick
///   • Cravings: what to expect → push → learn_lesson
///   • What quit medicines can do → push → learn_lesson
///   • Choose a path → push → bf_path
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class BfHomeExploreScreen extends StatelessWidget {
  const BfHomeExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'BreatheFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TEyebrow('Exploring · no date set'),
        TTitle('Learn at your own pace.'),
        TCard(variant: TCardVariant.coral, title: 'Craving now?', text: 'Rescue works without a plan', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Rescue', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TCard(key: const ValueKey('a:body[3]'), tag: 'bf', title: 'Cravings: what to expect', text: '4 min read', onTap: () => TNav.push(context, Routes.learnLesson)),
        TCard(key: const ValueKey('a:body[4]'), tag: 'bf', title: 'What quit medicines can do', text: 'Education only · 5 min', onTap: () => TNav.push(context, Routes.learnLesson)),
        TCard(variant: TCardVariant.mint, title: 'Ready when you are', text: 'Setting a date takes 2 minutes.', cta: TButton(key: const ValueKey('a:body[5].cta[0]'), label: 'Choose a path', onPressed: () => TNav.push(context, Routes.bfPath), small: true)),
      ],
    );
  }
}
