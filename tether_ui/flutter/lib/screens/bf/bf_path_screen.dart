// GENERATED from spec/screens/bf_path.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Choose path  ·  route `/p/bf/plan/path`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase plan
/// 
///
/// Actions (generated from spec/screens/bf_path.json):
///   • Back → back
///   • Talk to a person first? → tab → support
///   • Continue with this path → decide choice:bf_path.path: Selected path → Set a quit date: push → bf_date | Quit today: push → bf_support | Reduce gradually: push → bf_stepdown | Explore first: replace → bf_home_explore (onboarding: ob_setup)
/// API: —
class BfPathScreen extends StatelessWidget {
  const BfPathScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your path', pill: 'Plan 1 of 3'),
      children: [
        TTitle('What feels possible right now?'),
        TBody('There’s no wrong place to start.', tone: TTextTone.muted),
        TRadioList(fieldKey: 'bf_path.path', items: [TRadioItem('Set a quit date', sub: 'Prepare 7–14 days, then stop', badge: 'Recommended'), TRadioItem('Quit today', sub: 'Skip the calendar; extra support now'), TRadioItem('Reduce gradually', sub: 'Step down to zero over 4 weeks'), TRadioItem('Explore first', sub: 'No date. Lessons and Rescue only')], selected: 0),
        TCard(key: const ValueKey('a:body[3]'), variant: TCardVariant.coral, title: 'Talk to a person first?', text: 'Quitline counselor or your care team', onTap: () => TNav.tab(context, Routes.support)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue with this path', onPressed: () => TNav.branch(context, 'Selected path', <String, VoidCallback>{'Set a quit date': () => TNav.push(context, Routes.bfDate), 'Quit today': () => TNav.push(context, Routes.bfSupport), 'Reduce gradually': () => TNav.push(context, Routes.bfStepdown), 'Explore first': () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.bfHomeExplore))}, decide: 'choice:bf_path.path'), arrow: true),
      ],
    );
  }
}
