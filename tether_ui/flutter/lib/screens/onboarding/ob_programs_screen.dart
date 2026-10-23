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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.obProgramsHeaderTitle, pill: s.obProgramsHeaderPill),
      children: [
        TSteps(n: 1, total: 5),
        TTitle(s.obProgramsBodyN1Text),
        TBody(s.obProgramsBodyN2Text, tone: TTextTone.muted),
        TTileGrid(fieldKey: 'ob_programs.programs', tiles: [TTile(label: 'BreatheFree', sub: s.obProgramsBodyN3ItemsN0Sub, program: 'bf'), TTile(label: 'ScrollFree', sub: s.obProgramsBodyN3ItemsN1Sub, program: 'sf'), TTile(label: 'ClearAir', sub: s.obProgramsBodyN3ItemsN2Sub, program: 'ca'), TTile(label: 'Heartwise', sub: s.obProgramsBodyN3ItemsN3Sub, program: 'hw'), TTile(label: 'Steady', sub: s.obProgramsBodyN3ItemsN4Sub, program: 'st'), TTile(label: 'Ease', sub: s.obProgramsBodyN3ItemsN5Sub, program: 'ea'), TTile(label: 'Nourish', sub: s.obProgramsBodyN3ItemsN6Sub, program: 'nu'), TTile(label: 'Stride', sub: s.obProgramsBodyN3ItemsN7Sub, program: 'sd')]),
        TLink(key: const ValueKey('a:body[4]'), label: s.obProgramsBodyN4Label, onTap: () => TNav.push(context, Routes.catalog)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.obProgramsFooterN0Label, onPressed: () => TNav.push(context, Routes.obFocus), arrow: true),
      ],
    );
  }
}
