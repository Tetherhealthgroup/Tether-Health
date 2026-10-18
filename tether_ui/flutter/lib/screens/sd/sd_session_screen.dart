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
    return TScreen(
      header: THeader(title: 'Balance · 8 min', left: THeaderLeft.close, pill: '2 of 6'),
      background: TBackground.dark,
      children: [
        TIllustration(glyph: '⇅', tone: TTone.dark),
        TTitle('Heel-to-toe stand', size: TTitleSize.xl, center: true),
        TBody('Hold the chair. Place one foot in front of the other. Hold 10 seconds.', center: true),
        TBreathRing(value: '7'),
        TChips(fieldKey: 'sd_session.value', options: ['Audio on', 'Large text', 'Captions'], selected: ['Audio on', 'Large text', 'Captions']),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next exercise', onPressed: () => TNav.toast(context, 'Exercise 3 of 6'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Finish session', onPressed: () => TNav.submit(context, 'POST /v1/program-data/sd/sessions', then: () => TNav.toast(context, 'Session saved', then: () => TNav.replace(context, Routes.sdHome))), variant: TButtonVariant.white, arrow: true),
      ],
    );
  }
}
