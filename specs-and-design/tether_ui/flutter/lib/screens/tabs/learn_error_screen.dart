// GENERATED from spec/screens/learn_error.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Learn · error  ·  route `/learn?state=error`  ·  flow `tabs`  ·  kind `screen`
/// State: error of learn · phase resources
/// 
///
/// Actions (generated from spec/screens/learn_error.json):
///   • Avatar · Account → push → account
///   • Try again → replace → learn
///   • Open downloads → push → learn_lesson
///   • Tab · Today → tab → today
///   • Tab · Plans → tab → plans
///   • Tab · Progress → tab → progress
///   • Tab · Support → tab → support
/// API: —
class LearnErrorScreen extends StatelessWidget {
  const LearnErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.learnErrorHeaderTitle, left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'learn',
      children: [
        TIllustration(glyph: '!', tone: TTone.warn),
        TTitle(s.learnErrorBodyN1Text, center: true),
        TBody(s.learnErrorBodyN2Text, tone: TTextTone.muted, center: true),
        TButton(key: const ValueKey('a:body[3]'), label: s.learnErrorBodyN3Label, onPressed: () => TNav.replace(context, Routes.learn), arrow: true),
        TButton(key: const ValueKey('a:body[4]'), label: s.learnErrorBodyN4Label, onPressed: () => TNav.push(context, Routes.learnLesson, argument: 'bf.cravings-today'), variant: TButtonVariant.secondary),
      ],
    );
  }
}
