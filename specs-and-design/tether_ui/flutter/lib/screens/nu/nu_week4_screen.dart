// GENERATED from spec/screens/nu_week4.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Week 4 milestone  ·  route `/p/nu/milestone`  ·  flow `nu`  ·  kind `screen`
/// Default state · program nu · phase milestone
/// 
///
/// Actions (generated from spec/screens/nu_week4.json):
///   • Back → back
///   • Choose next habit → replace → nu_habit
/// API: —
class NuWeek4Screen extends StatelessWidget {
  const NuWeek4Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.nuWeek4HeaderTitle, pill: s.nuWeek4HeaderPill),
      children: [
        TIllustration(glyph: '4'),
        TTitle(s.nuWeek4BodyN1Text, size: TTitleSize.l, center: true),
        TBoundValues(keys: const ['nu.habits_tried', 'nu.days_done', 'nu.favorite_habit'], builder: (context, v) => TKeyValue(rows: [(s.nuWeek4BodyN2RowsN0N0, v.text('nu.habits_tried', '4')), (s.nuWeek4BodyN2RowsN1N0, v.text('nu.days_done', '19')), (s.nuWeek4BodyN2RowsN2N0, v.text('nu.favorite_habit', s.nuWeek4BodyN2RowsN2N1))])),
        TSegmented(fieldKey: 'nu_week4.how_do_you_feel_about_food_latel', options: ['Worse', 'Same', 'Better'], labels: [s.nuWeek4BodyN3OptionsN0, s.nuWeek4BodyN3OptionsN1, s.nuWeek4BodyN3OptionsN2], selected: 'Better', label: s.nuWeek4BodyN3Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.nuWeek4FooterN0Label, onPressed: () => TNav.replace(context, Routes.nuHabit), arrow: true),
      ],
    );
  }
}
