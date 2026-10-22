// GENERATED from spec/screens/sf_unplug_auth_notifications.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Notifications off  ·  route `/p/sf/unplug/permission?state=notifications`  ·  flow `unplug`  ·  kind `screen`
/// State: notifications off of sf_unplug_auth · program sf · phase plan
/// Copy needs clinical/legal review. Shown during setup when Screen Time / Android permissions are granted but notifications are off. Open phone settings fixes it; Check again reads the permission on return.
///
/// Actions (generated from spec/screens/sf_unplug_auth_notifications.json):
///   • Back → back
///   • Open phone settings → os_settings
///   • Check again → branch: Notification permission (checked on return) → On (iPhone): replace → sf_unplug_apps | On (Android): replace → sf_unplug_apps_android | Still off: toast “Notifications are still off. You can turn them on later in Settings.”
///   • Continue without notifications → branch: Platform → iPhone: replace → sf_unplug_apps | Android: replace → sf_unplug_apps_android
/// API: —
class SfUnplugAuthNotificationsScreen extends StatelessWidget {
  const SfUnplugAuthNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Unplug', pill: s.sfUnplugAuthNotificationsHeaderPill),
      children: [
        TBanner(kind: TBannerKind.info, text: s.sfUnplugAuthNotificationsBodyN0Text),
        TTitle(s.sfUnplugAuthNotificationsBodyN1Text),
        TBody(s.sfUnplugAuthNotificationsBodyN2Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugAuthNotificationsFooterN0Label, onPressed: () => TNav.osSettings(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugAuthNotificationsFooterN1Label, onPressed: () => TNav.branch(context, 'Notification permission (checked on return)', <String, VoidCallback>{'On (iPhone)': () => TNav.replace(context, Routes.sfUnplugApps), 'On (Android)': () => TNav.replace(context, Routes.sfUnplugAppsAndroid), 'Still off': () => TNav.toast(context, s.sfUnplugAuthNotificationsFooterN1ActionCasesN2ActionValue)}, device: const TBranchRef('unplug.setup.notifications_check', TAsk.notificationsCheck, 'sf_unplug_auth_notifications'), when: const <TAnswer, String>{TAnswer.denied: 'Still off'}, whenByPlatform: const <TAnswer, Map<TAnswer, String>>{TAnswer.granted: {TAnswer.ios: 'On (iPhone)', TAnswer.android: 'On (Android)'}}), variant: TButtonVariant.secondary),
        TLink(key: const ValueKey('a:footer[2]'), label: s.sfUnplugAuthNotificationsFooterN2Label, onTap: () => TNav.branch(context, 'Platform', <String, VoidCallback>{'iPhone': () => TNav.replace(context, Routes.sfUnplugApps), 'Android': () => TNav.replace(context, Routes.sfUnplugAppsAndroid)}, device: const TBranchRef('unplug.setup.continue_platform', TAsk.platform, 'sf_unplug_auth_notifications'), when: const <TAnswer, String>{TAnswer.ios: 'iPhone', TAnswer.android: 'Android'})),
      ],
    );
  }
}
