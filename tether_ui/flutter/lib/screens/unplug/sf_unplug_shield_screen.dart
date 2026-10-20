// GENERATED from spec/screens/sf_unplug_shield.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Pause screen (iPhone shield)  ·  route `/system/unplug/shield`  ·  flow `unplug`  ·  kind `fullscreen`
/// Default state · program sf · phase rescue
/// Copy needs clinical/legal review. iPhone system shield (ShieldConfiguration extension). Apple allows only an icon (here the Tether app icon), a title, a subtitle and two buttons, so this screen uses nothing else. Colors and text come from the shared intercept tokens. Not an app route: reference for the native shield. Take a breath posts a local notification with two actions: Take my breath and Get support (opens Rescue without the small step). Needs device validation.
///
/// Actions (generated from spec/screens/sf_unplug_shield.json):
///   • Take a breath → toast “Notification: open Tether to take your breath, or get support” then branch: Notification action → Take my breath: push → sf_unplug_gate | Get support: sheet → rescue_pick
///   • Open anyway → toast “Opened · 1 “open anyway” left today” then close
/// API: —
class SfUnplugShieldScreen extends StatelessWidget {
  const SfUnplugShieldScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      background: TBackground.dark,
      children: [
        SizedBox(height: 60.0),
        TIllustration(glyph: 'T', tone: TTone.dark),
        TTitle('Paused for a moment', size: TTitleSize.l, center: true),
        TBody('You asked to slow this one down. Video apps is on your list. 2 of 3 “open anyway” left today. Open Tether for support.', center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Take a breath', onPressed: () => TNav.toast(context, 'Notification: open Tether to take your breath, or get support', then: () => TNav.branch(context, 'Notification action', <String, VoidCallback>{'Take my breath': () => TNav.push(context, Routes.sfUnplugGate), 'Get support': () => TNav.sheet(context, Routes.rescuePick)}, device: const TBranchRef('unplug.shield.notification_action', TAsk.reference, 'sf_unplug_shield'))), variant: TButtonVariant.lime),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Open anyway', onTap: () => TNav.toast(context, 'Opened · 1 “open anyway” left today', then: () => TNav.close(context))),
      ],
    );
  }
}
