// GENERATED from spec/screens/be_questions.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Visit questions  ·  route `/p/be/questions`  ·  flow `be`  ·  kind `screen`
/// Default state · program be · phase milestone
/// 
///
/// Actions (generated from spec/screens/be_questions.json):
///   • Back → back
///   • Share with my care team → push → support_message_care
///   • Done → back
/// API: —
class BeQuestionsScreen extends StatelessWidget {
  const BeQuestionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.beQuestionsHeaderTitle, pill: s.beQuestionsHeaderPill),
      children: [
        TCard(children: [TChecklist(items: [TCheckItem(s.beQuestionsBodyN0ChildrenN0ItemsN0Label, value: 'What side effects should I call about?', done: true), TCheckItem(s.beQuestionsBodyN0ChildrenN0ItemsN1Label, value: 'Can I keep working during treatment?'), TCheckItem(s.beQuestionsBodyN0ChildrenN0ItemsN2Label, value: 'Who do I call after hours?')])]),
        TField(fieldKey: 'be_questions.add_a_question', label: s.beQuestionsBodyN1Label, placeholder: s.beQuestionsBodyN1Placeholder),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.beQuestionsFooterN0Label, onPressed: () => TNav.push(context, Routes.supportMessageCare), variant: TButtonVariant.secondary),
        TButton(key: const ValueKey('a:footer[1]'), label: s.beQuestionsFooterN1Label, onPressed: () => TNav.back(context), arrow: true),
      ],
    );
  }
}
