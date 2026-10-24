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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.eaCheckbackHeaderTitle, pill: s.eaCheckbackHeaderPill),
      children: [
        TTitle(s.eaCheckbackBodyN0Text),
        TSegmented(fieldKey: 'ea_checkback.value', options: ['Worse', 'Same', 'Better'], labels: [s.eaCheckbackBodyN1OptionsN0, s.eaCheckbackBodyN1OptionsN1, s.eaCheckbackBodyN1OptionsN2], selected: 'Same'),
        TChips(fieldKey: 'ea_checkback.did_you_reach_out_to_someone', options: ['Yes, I have an appointment', 'Not yet', 'I don’t want to'], labels: [s.eaCheckbackBodyN2OptionsN0, s.eaCheckbackBodyN2OptionsN1, s.eaCheckbackBodyN2OptionsN2], selected: ['Not yet'], multi: false, label: s.eaCheckbackBodyN2Label),
        TCard(variant: TCardVariant.mint, text: s.eaCheckbackBodyN3Text, cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: s.eaCheckbackBodyN3CtaN0Label, onPressed: () => TNav.push(context, Routes.learnLesson, argument: 'ea.what-to-say'), small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.eaCheckbackFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/ea/check-backs', screenId: 'ea_checkback', then: () => TNav.toast(context, s.eaCheckbackFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
