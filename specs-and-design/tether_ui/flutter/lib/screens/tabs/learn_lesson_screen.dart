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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.learnLessonHeaderTitle, pill: s.learnLessonHeaderPill),
      children: [
        TProgramTag(program: 'bf', extra: s.learnLessonBodyN0Extra),
        TTitle(s.learnLessonBodyN1Text, size: TTitleSize.l),
        TCard(variant: TCardVariant.dark, eyebrow: s.learnLessonBodyN2Eyebrow, title: s.learnLessonBodyN2Title, children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[2].children[0].items[0]'), label: s.learnLessonBodyN2ChildrenN0ItemsN0Label, onPressed: () => TNav.toast(context, s.learnLessonBodyN2ChildrenN0ItemsN0ActionValue), variant: TButtonVariant.lime, small: true), TButton(key: const ValueKey('a:body[2].children[0].items[1]'), label: s.learnLessonBodyN2ChildrenN0ItemsN1Label, onPressed: () => TNav.toast(context, s.learnLessonBodyN2ChildrenN0ItemsN1ActionValue), variant: TButtonVariant.ghostDark, small: true)])]),
        TBody(s.learnLessonBodyN3Text),
        TQuote(s.learnLessonBodyN4Text, caption: s.learnLessonBodyN4Caption),
        TBody(s.learnLessonBodyN5Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.learnLessonFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/records/lessons', screenId: 'learn_lesson', then: () => TNav.toast(context, s.learnLessonFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.learnLessonFooterN1Label, onTap: () => TNav.toast(context, s.learnLessonFooterN1ActionValue)),
      ],
    );
  }
}
