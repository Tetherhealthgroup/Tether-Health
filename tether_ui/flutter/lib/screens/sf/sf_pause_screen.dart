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
    return TScreen(
      header: THeader(title: 'Pause 60', left: THeaderLeft.close, pill: 'Urge rescue'),
      background: TBackground.indigo,
      children: [
        TTitle('Before you open it, one breath.', size: TTitleSize.l),
        TBody('What did you pick up your phone for?'),
        TBreathRing(value: '42', palette: TRingPalette.indigo),
        TChips(fieldKey: 'sf_pause.value', options: ['Message someone', 'Bored', 'Avoiding something', 'Can’t sleep'], selected: ['Bored'], multi: false),
        TCard(variant: TCardVariant.dark2, title: 'Bored? Try instead:', text: '2-min walk · text one real person · a short lesson'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'I’m good, put it down', onPressed: () => TNav.submit(context, 'POST /v1/program-data/sf/pauses', screenId: 'sf_pause', then: () => TNav.toast(context, 'Nice. Logged as a pause.', then: () => TNav.reset(context, Routes.today))), variant: TButtonVariant.white, arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Open anyway (logged as information)', onTap: () => TNav.toast(context, 'Logged. No judgment.', then: () => TNav.close(context))),
      ],
    );
  }
}
