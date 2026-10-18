// GENERATED from spec/screens/ob_programs.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Choose programs  ·  route `/onboarding/programs`  ·  flow `onboarding`  ·  kind `screen`
/// Default state · phase welcome
/// Multi-select. Continue is disabled with 0 selected ("Choose at least one program").
///
/// Actions (generated from spec/screens/ob_programs.json):
///   • Back → back
///   • See all 11 programs → push → catalog
///   • Continue with 2 programs → push → ob_focus
/// API: —
class ObProgramsScreen extends StatelessWidget {
  const ObProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Choose programs', pill: '1 of 5'),
      children: [
        TSteps(n: 1, total: 5),
        TTitle('What would you like support with?'),
        TBody('Choose any. You can add, pause or leave a program anytime.', tone: TTextTone.muted),
        TTileGrid(tiles: [TTile(label: 'BreatheFree', sub: 'Tobacco & nicotine', program: 'bf', selected: true), TTile(label: 'ScrollFree', sub: 'Social media use', program: 'sf', selected: true), TTile(label: 'ClearAir', sub: 'Respiratory health', program: 'ca'), TTile(label: 'Heartwise', sub: 'Cardiovascular health', program: 'hw'), TTile(label: 'Steady', sub: 'Diabetes & metabolic health', program: 'st'), TTile(label: 'Ease', sub: 'Mental & behavioral health', program: 'ea'), TTile(label: 'Nourish', sub: 'Obesity & nutrition', program: 'nu'), TTile(label: 'Stride', sub: 'Healthy aging', program: 'sd')]),
        TLink(key: const ValueKey('a:body[4]'), label: 'See all 11 programs', onTap: () => TNav.push(context, Routes.catalog)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue with 2 programs', onPressed: () => TNav.push(context, Routes.obFocus), arrow: true),
      ],
    );
  }
}
