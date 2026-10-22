// GENERATED from spec/screens/st_reset.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Meal energy reset  ·  route `/p/st/reset`  ·  flow `st`  ·  kind `screen`
/// Default state · program st · phase daily
/// 
///
/// Actions (generated from spec/screens/st_reset.json):
///   • Back → back
///   • Done → toast “Nice work” then back
/// API: —
class StResetScreen extends StatelessWidget {
  const StResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.stResetHeaderTitle, pill: s.stResetHeaderPill),
      children: [
        TTitle(s.stResetBodyN0Text),
        TCard(children: [TChecklist(items: [TCheckItem(s.stResetBodyN1ChildrenN0ItemsN0Label, value: 'Drink a glass of water', done: true), TCheckItem(s.stResetBodyN1ChildrenN0ItemsN1Label, value: 'Take a 10-minute walk if you can', done: true), TCheckItem(s.stResetBodyN1ChildrenN0ItemsN2Label, value: 'Take five slow breaths'), TCheckItem(s.stResetBodyN1ChildrenN0ItemsN3Label, value: 'Feel unwell? Contact your clinician')])]),
        TCard(variant: TCardVariant.mint, text: s.stResetBodyN2Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.stResetFooterN0Label, onPressed: () => TNav.toast(context, s.stResetFooterN0ActionValue, then: () => TNav.back(context)), arrow: true),
      ],
    );
  }
}
