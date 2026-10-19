// GENERATED from spec/screens/ea_checkback.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Check-back day  ·  route `/p/ea/check-back`  ·  flow `ea`  ·  kind `screen`
/// Default state · program ea · phase milestone
/// 
///
/// Actions (generated from spec/screens/ea_checkback.json):
///   • Back → back
///   • Show me → push → learn_lesson
///   • Save → POST /v1/program-data/ea/check-backs then toast “Saved” then back
/// API: —
class EaCheckbackScreen extends StatelessWidget {
  const EaCheckbackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Check-back', pill: '2 weeks'),
      children: [
        TTitle('It’s been two weeks. How are things?'),
        TSegmented(fieldKey: 'ea_checkback.value', options: ['Worse', 'Same', 'Better'], selected: 'Same'),
        TChips(fieldKey: 'ea_checkback.did_you_reach_out_to_someone', options: ['Yes, I have an appointment', 'Not yet', 'I don’t want to'], selected: ['Not yet'], multi: false, label: 'Did you reach out to someone?'),
        TCard(variant: TCardVariant.mint, text: 'That’s okay. Would a short list of what to say help?', cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: 'Show me', onPressed: () => TNav.push(context, Routes.learnLesson), small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'POST /v1/program-data/ea/check-backs', screenId: 'ea_checkback', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
