// GENERATED from spec/screens/ob_basics.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Shared basics  ·  route `/onboarding/basics`  ·  flow `onboarding`  ·  kind `screen`
/// Default state · phase onboarding
/// 
///
/// Actions (generated from spec/screens/ob_basics.json):
///   • Back → back
///   • Continue → push → ob_setup
/// API: —
class ObBasicsScreen extends StatelessWidget {
  const ObBasicsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'About you', pill: '4 of 5'),
      children: [
        TSteps(n: 4, total: 5),
        TEyebrow('Shared · asked once for all programs'),
        TTitle('A few basics'),
        TField(fieldKey: 'ob_basics.what_should_we_call_you', label: 'What should we call you?', value: 'Alex'),
        TField(fieldKey: 'ob_basics.age_range', label: 'Age range', value: '35–44', kind: TFieldKind.select),
        TSegmented(fieldKey: 'ob_basics.sleep_on_a_typical_night', options: ['< 5 h', '5–6 h', '7–8 h', '9+ h'], selected: '5–6 h', label: 'Sleep on a typical night'),
        TSegmented(fieldKey: 'ob_basics.usual_stress', options: ['Low', 'Some', 'High'], selected: 'High', label: 'Usual stress'),
        TCard(variant: TCardVariant.mint, title: 'Why we ask', text: 'These answers are shared by your programs, so you’re never asked twice. Age range sets which lessons and screenings apply.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue', onPressed: () => TNav.push(context, Routes.obSetup), arrow: true),
      ],
    );
  }
}
