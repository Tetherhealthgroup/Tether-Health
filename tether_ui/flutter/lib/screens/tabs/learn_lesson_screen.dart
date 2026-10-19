// GENERATED from spec/screens/learn_lesson.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Lesson  ·  route `/learn/:lesson`  ·  flow `tabs`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/learn_lesson.json):
///   • Back → back
///   • Play → toast “Playing audio”
///   • Transcript → toast “Transcript opened”
///   • Mark complete → POST /v1/records/lessons then toast “Lesson complete” then back
///   • Save for offline → toast “Saved for offline”
/// API: —
class LearnLessonScreen extends StatelessWidget {
  const LearnLessonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Lesson', pill: '4 min'),
      children: [
        TProgramTag(program: 'bf', extra: 'For quit day'),
        TTitle('Cravings: what to expect today', size: TTitleSize.l),
        TCard(variant: TCardVariant.dark, eyebrow: 'Audio · 3:12', title: 'Listen instead', children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[2].children[0].items[0]'), label: 'Play', onPressed: () => TNav.toast(context, 'Playing audio'), variant: TButtonVariant.lime, small: true), TButton(key: const ValueKey('a:body[2].children[0].items[1]'), label: 'Transcript', onPressed: () => TNav.toast(context, 'Transcript opened'), variant: TButtonVariant.ghostDark, small: true)])]),
        TBody('Most cravings peak and fade within 3–5 minutes. Knowing that makes them easier to ride out. Today, plan what you’ll do in the first 5 minutes of each craving.'),
        TQuote('This feeling will pass.', caption: 'From your plan'),
        TBody('Clinically reviewed · content v3.2 · Aug 2026', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Mark complete', onPressed: () => TNav.submit(context, 'POST /v1/records/lessons', screenId: 'learn_lesson', then: () => TNav.toast(context, 'Lesson complete', then: () => TNav.back(context))), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Save for offline', onTap: () => TNav.toast(context, 'Saved for offline')),
      ],
    );
  }
}
