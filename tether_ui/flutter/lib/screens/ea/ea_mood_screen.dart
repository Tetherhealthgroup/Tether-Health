// GENERATED from spec/screens/ea_mood.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Mood check-in  ·  route `/p/ea/mood`  ·  flow `ea`  ·  kind `screen`
/// Default state · program ea · phase daily
/// 
///
/// Actions (generated from spec/screens/ea_mood.json):
///   • Back → back
///   • Start → push → rescue_active
///   • Save → POST /v1/program-data/ea/moods then decide ea.selfharm: Self-harm option selected? → No: toast “Saved” then back | Yes: replace → crisis
/// API: —
class EaMoodScreen extends StatelessWidget {
  const EaMoodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.eaMoodHeaderTitle, pill: 'Ease'),
      children: [
        TSegmented(fieldKey: 'ea_mood.how_are_you_right_now', options: ['Very low', 'Low', 'Okay', 'Good', 'Great'], labels: [s.eaMoodBodyN0OptionsN0, s.eaMoodBodyN0OptionsN1, s.eaMoodBodyN0OptionsN2, s.eaMoodBodyN0OptionsN3, s.eaMoodBodyN0OptionsN4], selected: 'Low', label: s.eaMoodBodyN0Label),
        TChips(fieldKey: 'ea_mood.going_on', options: ['Work', 'Money', 'Family', 'Health', 'Lonely', 'Sleep', 'Thoughts of harming myself', 'Not sure'], labels: [s.eaMoodBodyN1OptionsN0, s.eaMoodBodyN1OptionsN1, s.eaMoodBodyN1OptionsN2, s.eaMoodBodyN1OptionsN3, s.eaMoodBodyN1OptionsN4, s.eaMoodBodyN1OptionsN5, s.eaMoodBodyN1OptionsN6, s.eaMoodBodyN1OptionsN7], selected: ['Work', 'Sleep'], label: s.eaMoodBodyN1Label),
        TCard(variant: TCardVariant.dark, eyebrow: s.eaMoodBodyN2Eyebrow, title: s.eaMoodBodyN2Title, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.eaMoodBodyN2CtaN0Label, onPressed: () => TNav.push(context, Routes.rescueActive), variant: TButtonVariant.lime, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.eaMoodFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/ea/moods', screenId: 'ea_mood', then: () => TNav.branch(context, 'Self-harm option selected?', <String, VoidCallback>{'No': () => TNav.toast(context, s.eaMoodFooterN0ActionThenCasesN0ActionValue, then: () => TNav.back(context)), 'Yes': () => TNav.replace(context, Routes.crisis)}, decide: 'ea.selfharm'), safety: TSafetyRoutes('ea.selfharm', <String, VoidCallback>{'Yes': () => TNav.replace(context, Routes.crisis)})), arrow: true),
      ],
    );
  }
}
