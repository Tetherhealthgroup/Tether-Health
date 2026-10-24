// GENERATED from spec/screens/be_q1.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Journey stage  ·  route `/p/be/onboarding/1`  ·  flow `be`  ·  kind `screen`
/// Default state · program be · phase onboarding
/// 
///
/// Actions (generated from spec/screens/be_q1.json):
///   • Back → back
///   • Next → decide choice:be_q1.stage: Journey stage → Lowering my risk: push → be_q2 | Going through treatment: replace → be_tx (onboarding: ob_setup) | After treatment: replace → be_survivor (onboarding: ob_setup) | Supporting someone: tab → learn
/// API: —
class BeQ1Screen extends StatelessWidget {
  const BeQ1Screen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.beQ1HeaderTitle, pill: s.beQ1HeaderPill),
      children: [
        TSteps(n: 1, total: 2),
        TTitle(s.beQ1BodyN1Text),
        TRadioList(fieldKey: 'be_q1.stage', items: [TRadioItem(s.beQ1BodyN2ItemsN0Label, value: 'Lowering my risk', sub: s.beQ1BodyN2ItemsN0Sub), TRadioItem(s.beQ1BodyN2ItemsN1Label, value: 'Going through treatment', sub: s.beQ1BodyN2ItemsN1Sub), TRadioItem(s.beQ1BodyN2ItemsN2Label, value: 'After treatment', sub: s.beQ1BodyN2ItemsN2Sub), TRadioItem(s.beQ1BodyN2ItemsN3Label, value: 'Supporting someone', sub: s.beQ1BodyN2ItemsN3Sub)], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.beQ1FooterN0Label, onPressed: () => TNav.branch(context, 'Journey stage', <String, VoidCallback>{'Lowering my risk': () => TNav.push(context, Routes.beQ2), 'Going through treatment': () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.beTx)), 'After treatment': () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.beSurvivor)), 'Supporting someone': () => TNav.tab(context, Routes.learn)}, decide: 'choice:be_q1.stage'), arrow: true),
      ],
    );
  }
}
