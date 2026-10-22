// GENERATED from spec/screens/sf_unplug_shield_firm.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Pause screen (iPhone shield, firm)  ·  route `/system/unplug/shield?state=firm`  ·  flow `unplug`  ·  kind `fullscreen`
/// State: no “open anyway” left of sf_unplug_shield · program sf · phase rescue
/// Copy needs clinical/legal review. iPhone system shield (ShieldConfiguration extension). Apple allows only an icon (here the Tether app icon), a title, a subtitle and two buttons, so this screen uses nothing else. Colors and text come from the shared intercept tokens. Not an app route: reference for the native shield. The second button is Get support: it posts a local notification that opens Rescue. Needs device validation.
///
/// Actions (generated from spec/screens/sf_unplug_shield_firm.json):
///   • Close the app → toast “The app stays closed.” then close
///   • Get support → toast “Notification: tap to open Rescue in Tether” then sheet → rescue_pick
/// API: —
class SfUnplugShieldFirmScreen extends StatelessWidget {
  const SfUnplugShieldFirmScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      background: TBackground.dark,
      children: [
        SizedBox(height: 60.0),
        TIllustration(glyph: 'T', tone: TTone.dark),
        TTitle(s.sfUnplugShieldFirmBodyN2Text, size: TTitleSize.l, center: true),
        TBody(s.sfUnplugShieldFirmBodyN3Text, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugShieldFirmFooterN0Label, onPressed: () => TNav.toast(context, s.sfUnplugShieldFirmFooterN0ActionValue, then: () => TNav.close(context)), variant: TButtonVariant.lime),
        TLink(key: const ValueKey('a:footer[1]'), label: s.sfUnplugShieldFirmFooterN1Label, onTap: () => TNav.toast(context, s.sfUnplugShieldFirmFooterN1ActionValue, then: () => TNav.sheet(context, Routes.rescuePick))),
      ],
    );
  }
}
