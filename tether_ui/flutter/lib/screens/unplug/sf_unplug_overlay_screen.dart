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
    return TScreen(
      background: TBackground.dark,
      children: [
        SizedBox(height: 24.0),
        TTitle('Paused for a moment', size: TTitleSize.l, center: true),
        TBody('You asked to slow this one down. Video apps is on your list.', center: true),
        TBreathRing(value: '30'),
        TBody('Breathe with the circle. 2 of 3 “open anyway” left today.', tone: TTextTone.small, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Close the app', onPressed: () => TNav.toast(context, 'The app stays closed.', then: () => TNav.close(context)), variant: TButtonVariant.lime),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Get support', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue),
        TLink(key: const ValueKey('a:footer[2]'), label: 'Open anyway', onTap: () => TNav.toast(context, 'Opened · 1 “open anyway” left today', then: () => TNav.close(context))),
      ],
    );
  }
}
