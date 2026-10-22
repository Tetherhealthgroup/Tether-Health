// GENERATED from spec/screens/sd_safety.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Home safety  ·  route `/p/sd/safety`  ·  flow `sd`  ·  kind `screen`
/// Default state · program sd · phase resources
/// 
///
/// Actions (generated from spec/screens/sd_safety.json):
///   • Back → back
///   • Save → PUT /v1/program-data/sd/safety then toast “Saved” then back
/// API: —
class SdSafetyScreen extends StatelessWidget {
  const SdSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sdSafetyHeaderTitle, pill: s.sdSafetyHeaderPill),
      children: [
        TTitle(s.sdSafetyBodyN0Text),
        TCard(children: [TChecklist(items: [TCheckItem(s.sdSafetyBodyN1ChildrenN0ItemsN0Label, value: 'Remove loose rugs', done: true), TCheckItem(s.sdSafetyBodyN1ChildrenN0ItemsN1Label, value: 'Night lights in hallway and bathroom', done: true), TCheckItem(s.sdSafetyBodyN1ChildrenN0ItemsN2Label, value: 'Grab bar in shower'), TCheckItem(s.sdSafetyBodyN1ChildrenN0ItemsN3Label, value: 'Stair rails on both sides'), TCheckItem(s.sdSafetyBodyN1ChildrenN0ItemsN4Label, value: 'Vision check this year')])]),
        TBody(s.sdSafetyBodyN2Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sdSafetyFooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/sd/safety', screenId: 'sd_safety', then: () => TNav.toast(context, s.sdSafetyFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
