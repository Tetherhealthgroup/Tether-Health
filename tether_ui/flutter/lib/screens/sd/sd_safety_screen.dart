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
    return TScreen(
      header: THeader(title: 'Home safety', pill: 'Checklist'),
      children: [
        TTitle('Make your home safer'),
        TCard(children: [TChecklist(items: [TCheckItem('Remove loose rugs', done: true), TCheckItem('Night lights in hallway and bathroom', done: true), TCheckItem('Grab bar in shower'), TCheckItem('Stair rails on both sides'), TCheckItem('Vision check this year')])]),
        TBody('2 of 5 done', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/sd/safety', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
