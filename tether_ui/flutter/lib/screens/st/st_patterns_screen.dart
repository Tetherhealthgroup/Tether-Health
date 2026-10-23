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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.stPatternsHeaderTitle, pill: 'Steady'),
      children: [
        TSegmented(fieldKey: 'st_patterns.value', options: ['7 days', '14 days', '30 days'], labels: [s.stPatternsBodyN0OptionsN0, s.stPatternsBodyN0OptionsN1, s.stPatternsBodyN0OptionsN2], selected: '14 days'),
        TBoundValues(keys: const ['st.after_meal_series'], builder: (context, v) => TLineChart(values: v.series('st.after_meal_series', const [196.0, 182.0, 175.0, 190.0, 168.0, 160.0, 172.0, 158.0, 165.0, 150.0, 162.0, 149.0]), color: TColors.program('st'), band: [80.0, 180.0], title: s.stPatternsBodyN1Title, unit: 'mg/dL · range ≤ 180')),
        TBoundValues(keys: const ['st.in_range', 'st.in_range_count', 'st.lows', 'st.last_low'], builder: (context, v) => TStatGrid(stats: [TStat(label: s.stPatternsBodyN2ItemsN0Label, value: v.text('st.in_range', '71%'), sub: v.text('st.in_range_count', s.stPatternsBodyN2ItemsN0Sub)), TStat(label: s.stPatternsBodyN2ItemsN1Label, value: v.text('st.lows', '1'), sub: v.text('st.last_low', s.stPatternsBodyN2ItemsN1Sub))])),
        TBoundValues(keys: const ['st.pattern_insight'], builder: (context, v) => TCard(variant: TCardVariant.mint, eyebrow: s.stPatternsBodyN3Eyebrow, title: v.text('st.pattern_insight', s.stPatternsBodyN3Title))),
      ],
    );
  }
}
