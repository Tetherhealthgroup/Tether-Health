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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'BreatheFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TEyebrow(s.bfHomeExploreBodyN0Text),
        TTitle(s.bfHomeExploreBodyN1Text),
        TCard(variant: TCardVariant.coral, title: s.bfHomeExploreBodyN2Title, text: s.bfHomeExploreBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.bfHomeExploreBodyN2CtaN0Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TCard(key: const ValueKey('a:body[3]'), tag: 'bf', title: s.bfHomeExploreBodyN3Title, text: s.bfHomeExploreBodyN3Text, onTap: () => TNav.push(context, Routes.learnLesson, argument: 'bf.cravings-what-to-expect')),
        TCard(key: const ValueKey('a:body[4]'), tag: 'bf', title: s.bfHomeExploreBodyN4Title, text: s.bfHomeExploreBodyN4Text, onTap: () => TNav.push(context, Routes.learnLesson, argument: 'bf.quit-medicines')),
        TCard(variant: TCardVariant.mint, title: s.bfHomeExploreBodyN5Title, text: s.bfHomeExploreBodyN5Text, cta: TButton(key: const ValueKey('a:body[5].cta[0]'), label: s.bfHomeExploreBodyN5CtaN0Label, onPressed: () => TNav.push(context, Routes.bfPath), small: true)),
      ],
    );
  }
}
