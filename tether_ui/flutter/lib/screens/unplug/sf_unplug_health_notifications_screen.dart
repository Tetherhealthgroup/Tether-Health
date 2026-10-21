// GENERATED from spec/screens/sf_unplug_health_notifications.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Tracking check · notifications off  ·  route `/p/sf/unplug/health?state=notifications`  ·  flow `unplug`  ·  kind `screen`
/// State: notifications off of sf_unplug_health · program sf · phase daily
/// Copy needs clinical/legal review. Same check on both platforms. Unplug keeps working; only the hand-off from the pause screen to Tether needs notifications.
///
/// Actions (generated from spec/screens/sf_unplug_health_notifications.json):
///   • Back → back
///   • Open phone settings → os_settings
///   • Check again → branch: Notification permission (checked on return) → On: replace → sf_unplug_health | Still off: toast “Notifications are still off.”
/// API: —
class SfUnplugHealthNotificationsScreen extends StatelessWidget {
  const SfUnplugHealthNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Tracking check'),
      children: [
        TBanner(kind: TBannerKind.info, text: 'Notifications are off. Unplug still pauses apps, but the pause screen can’t open Tether for you. Open Tether yourself for support.'),
        TChecklist(items: [TCheckItem('Screen Time permission', sub: 'Allowed', done: true), TCheckItem('Daily schedule', sub: 'Running', done: true), TCheckItem('Settings shared with the pause screen', sub: 'Ready', done: true), TCheckItem('Notifications', sub: 'Off in Settings')], label: 'Checks'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Open phone settings', onPressed: () => TNav.osSettings(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Check again', onPressed: () => TNav.branch(context, 'Notification permission (checked on return)', <String, VoidCallback>{'On': () => TNav.replace(context, Routes.sfUnplugHealth), 'Still off': () => TNav.toast(context, 'Notifications are still off.')}, device: const TBranchRef('unplug.health.notifications_check', TAsk.notificationsCheck, 'sf_unplug_health_notifications'), when: const <TAnswer, String>{TAnswer.granted: 'On', TAnswer.denied: 'Still off'}), variant: TButtonVariant.secondary),
      ],
    );
  }
}
