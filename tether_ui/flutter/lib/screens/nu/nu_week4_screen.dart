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
    return TScreen(
      header: THeader(title: 'Week 4', pill: 'Milestone'),
      children: [
        TIllustration(glyph: '4'),
        TTitle('Four weeks of small habits.', size: TTitleSize.l, center: true),
        TKeyValue(rows: [('Habits tried', '4'), ('Days done', '19'), ('Favorite', 'Water before meals')]),
        TSegmented(fieldKey: 'nu_week4.how_do_you_feel_about_food_latel', options: ['Worse', 'Same', 'Better'], selected: 'Better', label: 'How do you feel about food lately?'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Choose next habit', onPressed: () => TNav.replace(context, Routes.nuHabit), arrow: true),
      ],
    );
  }
}
