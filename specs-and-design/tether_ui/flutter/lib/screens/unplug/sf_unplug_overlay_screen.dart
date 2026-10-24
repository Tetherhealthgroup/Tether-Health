// GENERATED from spec/screens/sf_unplug_overlay.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Pause screen (Android overlay)  ·  route `/system/unplug/overlay`  ·  flow `unplug`  ·  kind `fullscreen`
/// Default state · program sf · phase rescue
/// Copy needs clinical/legal review. Drawn over the opened app by the foreground service (SYSTEM_ALERT_WINDOW), 0.5–1.5 s after it opens. Get support opens Tether at Rescue. The typed-sentence and quick-sum steps use the same layouts as the in-app small-step states. Not an app route: reference for the native overlay.
///
/// Actions (generated from spec/screens/sf_unplug_overlay.json):
///   • Close the app → toast “The app stays closed.” then close
///   • Get support → sheet → rescue_pick
///   • Open anyway → toast “Opened · 1 “open anyway” left today” then close
/// API: —
class SfUnplugOverlayScreen extends StatelessWidget {
  const SfUnplugOverlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      background: TBackground.dark,
      children: [
        SizedBox(height: 24.0),
        TTitle(s.sfUnplugOverlayBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.sfUnplugOverlayBodyN2Text, center: true),
        TBreathRing(value: '30'),
        TBody(s.sfUnplugOverlayBodyN4Text, tone: TTextTone.small, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugOverlayFooterN0Label, onPressed: () => TNav.toast(context, s.sfUnplugOverlayFooterN0ActionValue, then: () => TNav.close(context)), variant: TButtonVariant.lime),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugOverlayFooterN1Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue),
        TLink(key: const ValueKey('a:footer[2]'), label: s.sfUnplugOverlayFooterN2Label, onTap: () => TNav.toast(context, s.sfUnplugOverlayFooterN2ActionValue, then: () => TNav.close(context))),
      ],
    );
  }
}
