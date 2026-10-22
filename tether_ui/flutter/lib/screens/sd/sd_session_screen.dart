// GENERATED from spec/screens/sd_session.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Session player  ·  route `/p/sd/session`  ·  flow `sd`  ·  kind `fullscreen`
/// Default state · program sd · phase daily
/// 
///
/// Actions (generated from spec/screens/sd_session.json):
///   • Close → close
///   • Next exercise → toast “Exercise 3 of 6”
///   • Finish session → POST /v1/program-data/sd/sessions then toast “Session saved” then replace → sd_home
/// API: —
class SdSessionScreen extends StatelessWidget {
  const SdSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sdSessionHeaderTitle, left: THeaderLeft.close, pill: s.sdSessionHeaderPill),
      background: TBackground.dark,
      children: [
        TIllustration(glyph: '⇅', tone: TTone.dark),
        TTitle(s.sdSessionBodyN1Text, size: TTitleSize.xl, center: true),
        TBody(s.sdSessionBodyN2Text, center: true),
        TBreathRing(value: '7'),
        TChips(fieldKey: 'sd_session.value', options: ['Audio on', 'Large text', 'Captions'], labels: [s.sdSessionBodyN4OptionsN0, s.sdSessionBodyN4OptionsN1, s.sdSessionBodyN4OptionsN2], selected: ['Audio on', 'Large text', 'Captions']),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sdSessionFooterN0Label, onPressed: () => TNav.toast(context, s.sdSessionFooterN0ActionValue), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sdSessionFooterN1Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/sd/sessions', screenId: 'sd_session', then: () => TNav.toast(context, s.sdSessionFooterN1ActionThenValue, then: () => TNav.replace(context, Routes.sdHome))), variant: TButtonVariant.white, arrow: true),
      ],
    );
  }
}
