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
    return TScreen(
      header: THeader(title: 'Unplug', pill: 'Step 1 of 3'),
      children: [
        TTitle('Two Android settings for Unplug'),
        TBody('Android asks for each one separately. You can turn either off later, and Unplug will tell you if it stops working.', tone: TTextTone.muted),
        TChecklist(items: [TCheckItem('Usage access', sub: 'On · lets Unplug see which app is open and for how long', done: true), TCheckItem('Display over other apps', sub: 'Off · lets Unplug show the pause screen'), TCheckItem('Notifications', sub: 'Android shows a quiet “Tether is running” notice while Unplug is on')], label: 'Needed'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Turn on display over apps', onPressed: () => TNav.osSettings(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Turn on usage access', onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
        TLink(key: const ValueKey('a:footer[2]'), label: 'I’ve turned them on', onTap: () => TNav.branch(context, 'Android permissions (checked on return)', <String, VoidCallback>{'All on': () => TNav.replace(context, Routes.sfUnplugAppsAndroid), 'Notifications off': () => TNav.replace(context, Routes.sfUnplugAuthNotifications), 'Missing': () => TNav.toast(context, 'Unplug still needs both settings.')})),
      ],
    );
  }
}
