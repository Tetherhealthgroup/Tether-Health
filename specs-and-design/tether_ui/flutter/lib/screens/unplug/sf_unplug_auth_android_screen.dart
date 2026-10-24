// GENERATED from spec/screens/sf_unplug_auth_android.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Android permissions for Unplug  ·  route `/p/sf/unplug/permission?state=android`  ·  flow `unplug`  ·  kind `screen`
/// State: android of sf_unplug_auth · program sf · phase plan
/// Copy needs clinical/legal review. Android has no single prompt: usage access and the overlay permission are separate settings pages, checked again when the person returns (authorizationStatus on resume). The foreground service needs a visible notification; its text is generic.
///
/// Actions (generated from spec/screens/sf_unplug_auth_android.json):
///   • Back → back
///   • Turn on display over apps → os_settings
///   • Turn on usage access → os_settings
///   • I’ve turned them on → branch: Android permissions (checked on return) → All on: replace → sf_unplug_apps_android | Notifications off: replace → sf_unplug_auth_notifications | Missing: toast “Unplug still needs both settings.”
/// API: —
class SfUnplugAuthAndroidScreen extends StatelessWidget {
  const SfUnplugAuthAndroidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Unplug', pill: s.sfUnplugAuthAndroidHeaderPill),
      children: [
        TTitle(s.sfUnplugAuthAndroidBodyN0Text),
        TBody(s.sfUnplugAuthAndroidBodyN1Text, tone: TTextTone.muted),
        TChecklist(items: [TCheckItem(s.sfUnplugAuthAndroidBodyN2ItemsN0Label, value: 'Usage access', sub: s.sfUnplugAuthAndroidBodyN2ItemsN0Sub, done: true), TCheckItem(s.sfUnplugAuthAndroidBodyN2ItemsN1Label, value: 'Display over other apps', sub: s.sfUnplugAuthAndroidBodyN2ItemsN1Sub), TCheckItem(s.sfUnplugAuthAndroidBodyN2ItemsN2Label, value: 'Notifications', sub: s.sfUnplugAuthAndroidBodyN2ItemsN2Sub)], label: s.sfUnplugAuthAndroidBodyN2Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugAuthAndroidFooterN0Label, onPressed: () => TNav.osSettings(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugAuthAndroidFooterN1Label, onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
        TLink(key: const ValueKey('a:footer[2]'), label: s.sfUnplugAuthAndroidFooterN2Label, onTap: () => TNav.branch(context, 'Android permissions (checked on return)', <String, VoidCallback>{'All on': () => TNav.replace(context, Routes.sfUnplugAppsAndroid), 'Notifications off': () => TNav.replace(context, Routes.sfUnplugAuthNotifications), 'Missing': () => TNav.toast(context, s.sfUnplugAuthAndroidFooterN2ActionCasesN2ActionValue)}, device: const TBranchRef('unplug.setup.android_check', TAsk.unplugAndroidCheck, 'sf_unplug_auth_android'), when: const <TAnswer, String>{TAnswer.allOn: 'All on', TAnswer.notificationsOff: 'Notifications off', TAnswer.missing: 'Missing'})),
      ],
    );
  }
}
