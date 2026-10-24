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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sdQ1HeaderTitle, pill: s.sdQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 1),
        TSegmented(fieldKey: 'sd_q1.in_the_last_year_have_you_fallen', options: ['No', 'Once', '2+ times'], labels: [s.sdQ1BodyN1OptionsN0, s.sdQ1BodyN1OptionsN1, s.sdQ1BodyN1OptionsN2], selected: 'Once', label: s.sdQ1BodyN1Label),
        TSegmented(fieldKey: 'sd_q1.do_you_feel_unsteady_standing_or', options: ['No', 'Sometimes', 'Often'], labels: [s.sdQ1BodyN2OptionsN0, s.sdQ1BodyN2OptionsN1, s.sdQ1BodyN2OptionsN2], selected: 'Sometimes', label: s.sdQ1BodyN2Label),
        TSegmented(fieldKey: 'sd_q1.do_you_worry_about_falling', options: ['No', 'A little', 'A lot'], labels: [s.sdQ1BodyN3OptionsN0, s.sdQ1BodyN3OptionsN1, s.sdQ1BodyN3OptionsN2], selected: 'A little', label: s.sdQ1BodyN3Label),
        TCard(variant: TCardVariant.mint, text: s.sdQ1BodyN4Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sdQ1FooterN0Label, onPressed: () => TNav.push(context, Routes.sdPlan), arrow: true),
      ],
    );
  }
}
