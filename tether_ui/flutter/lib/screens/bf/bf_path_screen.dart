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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfPathHeaderTitle, pill: s.bfPathHeaderPill),
      children: [
        TTitle(s.bfPathBodyN0Text),
        TBody(s.bfPathBodyN1Text, tone: TTextTone.muted),
        TRadioList(fieldKey: 'bf_path.path', items: [TRadioItem(s.bfPathBodyN2ItemsN0Label, value: 'Set a quit date', sub: s.bfPathBodyN2ItemsN0Sub, badge: s.bfPathBodyN2ItemsN0Badge), TRadioItem(s.bfPathBodyN2ItemsN1Label, value: 'Quit today', sub: s.bfPathBodyN2ItemsN1Sub), TRadioItem(s.bfPathBodyN2ItemsN2Label, value: 'Reduce gradually', sub: s.bfPathBodyN2ItemsN2Sub), TRadioItem(s.bfPathBodyN2ItemsN3Label, value: 'Explore first', sub: s.bfPathBodyN2ItemsN3Sub)], selected: 0),
        TCard(key: const ValueKey('a:body[3]'), variant: TCardVariant.coral, title: s.bfPathBodyN3Title, text: s.bfPathBodyN3Text, onTap: () => TNav.tab(context, Routes.support)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfPathFooterN0Label, onPressed: () => TNav.branch(context, 'Selected path', <String, VoidCallback>{'Set a quit date': () => TNav.push(context, Routes.bfDate), 'Quit today': () => TNav.push(context, Routes.bfSupport), 'Reduce gradually': () => TNav.push(context, Routes.bfStepdown), 'Explore first': () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.bfHomeExplore))}, decide: 'choice:bf_path.path'), arrow: true),
      ],
    );
  }
}
