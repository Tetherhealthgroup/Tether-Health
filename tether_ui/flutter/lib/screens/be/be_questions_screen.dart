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
    return TScreen(
      header: THeader(title: 'Questions for my visit', pill: 'Oct 22'),
      children: [
        TCard(children: [TChecklist(items: [TCheckItem('What side effects should I call about?', done: true), TCheckItem('Can I keep working during treatment?'), TCheckItem('Who do I call after hours?')])]),
        TField(fieldKey: 'be_questions.add_a_question', label: 'Add a question', placeholder: 'Type a question…'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Share with my care team', onPressed: () => TNav.push(context, Routes.supportMessageCare), variant: TButtonVariant.secondary),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Done', onPressed: () => TNav.back(context), arrow: true),
      ],
    );
  }
}
