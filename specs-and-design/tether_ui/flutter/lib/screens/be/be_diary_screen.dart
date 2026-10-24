// GENERATED from spec/screens/be_diary.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Treatment diary  ·  route `/p/be/diary`  ·  flow `be`  ·  kind `screen`
/// Default state · program be · phase daily
/// 
///
/// Actions (generated from spec/screens/be_diary.json):
///   • Back → back
///   • Call → call (555) 010-7000
///   • Save → POST /v1/program-data/be/diary then toast “Saved” then back
/// API: —
class BeDiaryScreen extends StatelessWidget {
  const BeDiaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.beDiaryHeaderTitle, pill: s.beDiaryHeaderPill),
      children: [
        TTitle(s.beDiaryBodyN0Text),
        TSliderField(fieldKey: 'be_diary.fatigue', label: s.beDiaryBodyN1Label, value: 6.0, min: 0.0, max: 10.0, minLabel: '0', maxLabel: '10', color: TColors.program('be')),
        TChips(fieldKey: 'be_diary.anything_else', options: ['Nausea', 'Pain', 'Mouth sores', 'Numbness', 'Low mood'], labels: [s.beDiaryBodyN2OptionsN0, s.beDiaryBodyN2OptionsN1, s.beDiaryBodyN2OptionsN2, s.beDiaryBodyN2OptionsN3, s.beDiaryBodyN2OptionsN4], selected: ['Nausea'], label: s.beDiaryBodyN2Label),
        TCard(variant: TCardVariant.urgent, title: s.beDiaryBodyN3Title, text: s.beDiaryBodyN3Text, cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: s.beDiaryBodyN3CtaN0Label, onPressed: () => TNav.call(context, '(555) 010-7000', label: 'Call oncology team'), variant: TButtonVariant.danger, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.beDiaryFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/be/diary', screenId: 'be_diary', then: () => TNav.toast(context, s.beDiaryFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
