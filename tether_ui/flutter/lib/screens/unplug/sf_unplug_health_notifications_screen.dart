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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugHealthNotificationsHeaderTitle),
      children: [
        TBanner(kind: TBannerKind.info, text: s.sfUnplugHealthNotificationsBodyN0Text),
        TChecklist(items: [TCheckItem(s.sfUnplugHealthNotificationsBodyN1ItemsN0Label, value: 'Screen Time permission', sub: s.sfUnplugHealthNotificationsBodyN1ItemsN0Sub, done: true), TCheckItem(s.sfUnplugHealthNotificationsBodyN1ItemsN1Label, value: 'Daily schedule', sub: s.sfUnplugHealthNotificationsBodyN1ItemsN1Sub, done: true), TCheckItem(s.sfUnplugHealthNotificationsBodyN1ItemsN2Label, value: 'Settings shared with the pause screen', sub: s.sfUnplugHealthNotificationsBodyN1ItemsN2Sub, done: true), TCheckItem(s.sfUnplugHealthNotificationsBodyN1ItemsN3Label, value: 'Notifications', sub: s.sfUnplugHealthNotificationsBodyN1ItemsN3Sub)], label: s.sfUnplugHealthNotificationsBodyN1Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugHealthNotificationsFooterN0Label, onPressed: () => TNav.osSettings(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugHealthNotificationsFooterN1Label, onPressed: () => TNav.branch(context, 'Notification permission (checked on return)', <String, VoidCallback>{'On': () => TNav.replace(context, Routes.sfUnplugHealth), 'Still off': () => TNav.toast(context, s.sfUnplugHealthNotificationsFooterN1ActionCasesN1ActionValue)}, device: const TBranchRef('unplug.health.notifications_check', TAsk.notificationsCheck, 'sf_unplug_health_notifications'), when: const <TAnswer, String>{TAnswer.granted: 'On', TAnswer.denied: 'Still off'}), variant: TButtonVariant.secondary),
      ],
    );
  }
}
