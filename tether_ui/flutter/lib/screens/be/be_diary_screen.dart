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
    return TScreen(
      header: THeader(title: 'Treatment diary', pill: 'Treatment'),
      children: [
        TTitle('How are you feeling today?'),
        TSliderField(fieldKey: 'be_diary.fatigue', label: 'Fatigue', value: 6.0, min: 0.0, max: 10.0, minLabel: '0', maxLabel: '10', color: TColors.program('be')),
        TChips(fieldKey: 'be_diary.anything_else', options: ['Nausea', 'Pain', 'Mouth sores', 'Numbness', 'Low mood'], selected: ['Nausea'], label: 'Anything else?'),
        TCard(variant: TCardVariant.urgent, title: 'Fever of 100.4°F (38°C) or higher?', text: 'Call your oncology team now.', cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: 'Call', onPressed: () => TNav.call(context, '(555) 010-7000', label: 'Call oncology team'), variant: TButtonVariant.danger, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'POST /v1/program-data/be/diary', screenId: 'be_diary', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
