// GENERATED from spec/screens/sd_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Falls check  ·  route `/p/sd/onboarding/1`  ·  flow `sd`  ·  kind `screen`
/// Default state · program sd · phase onboarding
/// 
///
/// Actions (generated from spec/screens/sd_q1.json):
///   • Back → back
///   • Next → push → sd_plan
/// API: —
class SdQ1Screen extends StatelessWidget {
  const SdQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'How you move', pill: '1 of 1'),
      children: [
        TSteps(n: 1, total: 1),
        TSegmented(fieldKey: 'sd_q1.in_the_last_year_have_you_fallen', options: ['No', 'Once', '2+ times'], selected: 'Once', label: 'In the last year, have you fallen?'),
        TSegmented(fieldKey: 'sd_q1.do_you_feel_unsteady_standing_or', options: ['No', 'Sometimes', 'Often'], selected: 'Sometimes', label: 'Do you feel unsteady standing or walking?'),
        TSegmented(fieldKey: 'sd_q1.do_you_worry_about_falling', options: ['No', 'A little', 'A lot'], selected: 'A little', label: 'Do you worry about falling?'),
        TCard(variant: TCardVariant.mint, text: 'A fall plus feeling unsteady is worth mentioning to your clinician. We’ll add it to your visit list.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next', onPressed: () => TNav.push(context, Routes.sdPlan), arrow: true),
      ],
    );
  }
}
