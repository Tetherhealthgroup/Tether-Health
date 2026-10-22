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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugSessionActiveHeaderTitle, left: THeaderLeft.close, pill: s.sfUnplugSessionActiveHeaderPill),
      children: [
        TTimer(value: '32:18', label: s.sfUnplugSessionActiveBodyN0Label),
        TBody(s.sfUnplugSessionActiveBodyN1Text, center: true),
        TCard(variant: TCardVariant.coral, title: s.sfUnplugSessionActiveBodyN2Title, text: s.sfUnplugSessionActiveBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.sfUnplugSessionActiveBodyN2CtaN0Label, onPressed: () => TNav.push(context, Routes.sfPause), variant: TButtonVariant.rescue, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugSessionActiveFooterN0Label, onPressed: () => TNav.sheet(context, Routes.sfUnplugSessionEnd), variant: TButtonVariant.secondary),
      ],
    );
  }
}
