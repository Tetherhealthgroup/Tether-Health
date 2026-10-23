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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.learnHeaderTitle, left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'learn',
      children: [
        TField(fieldKey: 'learn.search', label: s.learnBodyN0Label, placeholder: s.learnBodyN0Placeholder, kind: TFieldKind.search),
        TChips(fieldKey: 'learn.value', options: ['For you', 'BreatheFree', 'ScrollFree', 'ClearAir'], labels: [s.learnBodyN1OptionsN0, 'BreatheFree', 'ScrollFree', 'ClearAir'], selected: ['For you'], multi: false, dots: {'BreatheFree': TColors.program('bf'), 'ScrollFree': TColors.program('sf'), 'ClearAir': TColors.program('ca')}),
        TCard(key: const ValueKey('a:body[2]'), variant: TCardVariant.dark, tag: 'bf', tagExtra: s.learnBodyN2TagExtra, title: s.learnBodyN2Title, text: s.learnBodyN2Text, onTap: () => TNav.push(context, Routes.learnLesson, argument: 'bf.cravings-today')),
        TCard(key: const ValueKey('a:body[3]'), tag: 'sf', tagExtra: s.learnBodyN3TagExtra, title: s.learnBodyN3Title, onTap: () => TNav.push(context, Routes.learnLesson, argument: 'sf.one-more-video')),
        TCard(key: const ValueKey('a:body[4]'), tag: 'ca', tagExtra: s.learnBodyN4TagExtra, title: s.learnBodyN4Title, onTap: () => TNav.push(context, Routes.learnLesson, argument: 'ca.lungs-recover')),
        TBody(s.learnBodyN5Text, tone: TTextTone.small),
      ],
    );
  }
}
