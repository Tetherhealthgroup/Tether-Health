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
    return TScreen(
      header: THeader(title: 'Meal energy reset', pill: '3 min'),
      children: [
        TTitle('Feeling the post-meal slump?'),
        TCard(children: [TChecklist(items: [TCheckItem('Drink a glass of water', done: true), TCheckItem('Take a 10-minute walk if you can', done: true), TCheckItem('Take five slow breaths'), TCheckItem('Feel unwell? Contact your clinician')])]),
        TCard(variant: TCardVariant.mint, text: 'Walking after meals helps some people’s readings. Check with your clinician what’s right for you.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Done', onPressed: () => TNav.toast(context, 'Nice work', then: () => TNav.back(context)), arrow: true),
      ],
    );
  }
}
