// GENERATED from spec/screens/nu_reset.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Off-track reset  ·  route `/p/nu/reset`  ·  flow `nu`  ·  kind `screen`
/// Default state · program nu · phase rescue
/// 
///
/// Actions (generated from spec/screens/nu_reset.json):
///   • Back → back
///   • Continue → decide choice:nu_reset.option: Selected option → Keep this habit: toast “Fresh start today” then replace → nu_home | Make it smaller: toast “Goal set to 3 nights” then replace → nu_home | Pick a different habit: replace → nu_habit
/// API: —
class NuResetScreen extends StatelessWidget {
  const NuResetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Off track?', pill: 'Reset'),
      children: [
        TTitle('Busy week? That’s okay.'),
        TBody('Missing days doesn’t undo the ones you did.', tone: TTextTone.muted),
        TRadioList(fieldKey: 'nu_reset.option', items: [TRadioItem('Keep this habit, start fresh today'), TRadioItem('Make it smaller', sub: '3 nights instead of 5'), TRadioItem('Pick a different habit')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue', onPressed: () => TNav.branch(context, 'Selected option', <String, VoidCallback>{'Keep this habit': () => TNav.toast(context, 'Fresh start today', then: () => TNav.replace(context, Routes.nuHome)), 'Make it smaller': () => TNav.toast(context, 'Goal set to 3 nights', then: () => TNav.replace(context, Routes.nuHome)), 'Pick a different habit': () => TNav.replace(context, Routes.nuHabit)}, decide: 'choice:nu_reset.option'), arrow: true),
      ],
    );
  }
}
