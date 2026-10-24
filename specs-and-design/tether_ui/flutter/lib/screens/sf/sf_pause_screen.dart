// GENERATED from spec/screens/sf_pause.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Pause 60  ·  route `/p/sf/pause`  ·  flow `sf`  ·  kind `fullscreen`
/// Default state · program sf · phase rescue
/// 
///
/// Actions (generated from spec/screens/sf_pause.json):
///   • Close → close
///   • I’m good, put it down → POST /v1/program-data/sf/pauses then toast “Nice. Logged as a pause.” then reset → today
///   • Open anyway (logged as information) → toast “Logged. No judgment.” then close
/// API: —
class SfPauseScreen extends StatelessWidget {
  const SfPauseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfPauseHeaderTitle, left: THeaderLeft.close, pill: s.sfPauseHeaderPill),
      background: TBackground.indigo,
      children: [
        TTitle(s.sfPauseBodyN0Text, size: TTitleSize.l),
        TBody(s.sfPauseBodyN1Text),
        TBreathRing(value: '42', palette: TRingPalette.indigo),
        TChips(fieldKey: 'sf_pause.value', options: ['Message someone', 'Bored', 'Avoiding something', 'Can’t sleep'], labels: [s.sfPauseBodyN3OptionsN0, s.sfPauseBodyN3OptionsN1, s.sfPauseBodyN3OptionsN2, s.sfPauseBodyN3OptionsN3], selected: ['Bored'], multi: false),
        TCard(variant: TCardVariant.dark2, title: s.sfPauseBodyN4Title, text: s.sfPauseBodyN4Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfPauseFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/sf/pauses', screenId: 'sf_pause', then: () => TNav.toast(context, s.sfPauseFooterN0ActionThenValue, then: () => TNav.reset(context, Routes.today))), variant: TButtonVariant.white, arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.sfPauseFooterN1Label, onTap: () => TNav.toast(context, s.sfPauseFooterN1ActionValue, then: () => TNav.close(context))),
      ],
    );
  }
}
