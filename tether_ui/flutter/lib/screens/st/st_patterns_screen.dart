// GENERATED from spec/screens/st_patterns.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Patterns  ·  route `/p/st/patterns`  ·  flow `st`  ·  kind `screen`
/// Default state · program st · phase resources
/// 
///
/// Actions (generated from spec/screens/st_patterns.json):
///   • Back → back
/// API: —
class StPatternsScreen extends StatelessWidget {
  const StPatternsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Patterns', pill: 'Steady'),
      children: [
        TSegmented(fieldKey: 'st_patterns.value', options: ['7 days', '14 days', '30 days'], selected: '14 days'),
        TLineChart(values: [196.0, 182.0, 175.0, 190.0, 168.0, 160.0, 172.0, 158.0, 165.0, 150.0, 162.0, 149.0], color: TColors.program('st'), band: [80.0, 180.0], title: 'After meals', unit: 'mg/dL · range ≤ 180'),
        TStatGrid(stats: [TStat(label: 'In your range', value: '71%', sub: 'of 38 readings'), TStat(label: 'Lows', value: '1', sub: 'Oct 9 · treated')]),
        TCard(variant: TCardVariant.mint, eyebrow: 'Pattern', title: 'Readings were higher on nights with less than 6 h sleep.'),
      ],
    );
  }
}
