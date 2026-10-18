// GENERATED from spec/screens/learn.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Learn  ·  route `/learn`  ·  flow `tabs`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/learn.json):
///   • Avatar · Account → push → account
///   • Cravings: what to expect today → push → learn_lesson
///   • Why “one more video” never feels like enough → push → learn_lesson
///   • How your lungs recover after you quit → push → learn_lesson
///   • Tab · Today → tab → today
///   • Tab · Plans → tab → plans
///   • Tab · Progress → tab → progress
///   • Tab · Support → tab → support
/// API: GET /v1/catalogue/lessons?enrolled=true
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Learn', left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'learn',
      children: [
        TField(fieldKey: 'learn.search', label: 'Search', placeholder: 'Search cravings, sleep, blood pressure…', kind: TFieldKind.search),
        TChips(fieldKey: 'learn.value', options: ['For you', 'BreatheFree', 'ScrollFree', 'ClearAir'], selected: ['For you'], multi: false, dots: {'BreatheFree': TColors.program('bf'), 'ScrollFree': TColors.program('sf'), 'ClearAir': TColors.program('ca')}),
        TCard(key: const ValueKey('a:body[2]'), variant: TCardVariant.dark, tag: 'bf', tagExtra: 'For quit day', title: 'Cravings: what to expect today', text: '4 min read · 3:12 audio · downloaded', onTap: () => TNav.push(context, Routes.learnLesson)),
        TCard(key: const ValueKey('a:body[3]'), tag: 'sf', tagExtra: '2 min', title: 'Why “one more video” never feels like enough', onTap: () => TNav.push(context, Routes.learnLesson)),
        TCard(key: const ValueKey('a:body[4]'), tag: 'ca', tagExtra: 'Learn only', title: 'How your lungs recover after you quit', onTap: () => TNav.push(context, Routes.learnLesson)),
        TBody('Clinically reviewed · Library v4.1 · English and Spanish', tone: TTextTone.small),
      ],
    );
  }
}
