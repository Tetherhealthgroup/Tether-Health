// GENERATED from spec/screens/sf_unplug_session_active.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Focus session running  ·  route `/p/sf/unplug/session/active`  ·  flow `unplug`  ·  kind `fullscreen`
/// Default state · program sf · phase rescue
/// Copy needs clinical/legal review. Close leaves the session running. The session ends by itself at the end time (see Session complete).
///
/// Actions (generated from spec/screens/sf_unplug_session_active.json):
///   • Close → close
///   • Pause 60 → push → sf_pause
///   • End early → sheet → sf_unplug_session_end
/// API: —
class SfUnplugSessionActiveScreen extends StatelessWidget {
  const SfUnplugSessionActiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Focus session', left: THeaderLeft.close, pill: 'Strict'),
      children: [
        TTimer(value: '32:18', label: 'left of 45 min · until 3:45 PM'),
        TBody('Video apps and Feeds are paused. Tether, phone calls and emergency calls stay open.', center: true),
        TCard(variant: TCardVariant.coral, title: 'Urge to check?', text: 'Take 60 seconds first', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Pause 60', onPressed: () => TNav.push(context, Routes.sfPause), variant: TButtonVariant.rescue, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'End early', onPressed: () => TNav.sheet(context, Routes.sfUnplugSessionEnd), variant: TButtonVariant.secondary),
      ],
    );
  }
}
