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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.obBasicsHeaderTitle, pill: s.obBasicsHeaderPill),
      children: [
        TSteps(n: 4, total: 5),
        TEyebrow(s.obBasicsBodyN1Text),
        TTitle(s.obBasicsBodyN2Text),
        TField(fieldKey: 'ob_basics.what_should_we_call_you', label: s.obBasicsBodyN3Label, placeholder: s.obBasicsBodyN3Placeholder),
        TField(fieldKey: 'ob_basics.age_range', label: s.obBasicsBodyN4Label, placeholder: '35–44', kind: TFieldKind.select),
        TSegmented(fieldKey: 'ob_basics.sleep_on_a_typical_night', options: ['< 5 h', '5–6 h', '7–8 h', '9+ h'], labels: [s.obBasicsBodyN5OptionsN0, s.obBasicsBodyN5OptionsN1, s.obBasicsBodyN5OptionsN2, s.obBasicsBodyN5OptionsN3], selected: '5–6 h', label: s.obBasicsBodyN5Label),
        TSegmented(fieldKey: 'ob_basics.usual_stress', options: ['Low', 'Some', 'High'], labels: [s.obBasicsBodyN6OptionsN0, s.obBasicsBodyN6OptionsN1, s.obBasicsBodyN6OptionsN2], selected: 'High', label: s.obBasicsBodyN6Label),
        TCard(variant: TCardVariant.mint, title: s.obBasicsBodyN7Title, text: s.obBasicsBodyN7Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.obBasicsFooterN0Label, onPressed: () => TNav.push(context, Routes.obSetup), arrow: true),
      ],
    );
  }
}
