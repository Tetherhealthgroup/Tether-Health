// GENERATED from spec/screens/sf_unplug_auth_denied.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Screen Time not allowed  ·  route `/p/sf/unplug/permission?state=denied`  ·  flow `unplug`  ·  kind `screen`
/// State: permission denied of sf_unplug_auth · program sf · phase plan
/// Copy needs clinical/legal review.
///
/// Actions (generated from spec/screens/sf_unplug_auth_denied.json):
///   • Back → back
///   • Try again → branch: Screen Time authorization (iOS Family Controls, individual) → Approved: replace → sf_unplug_apps | Denied: toast “Still not allowed. You can turn it on later in Settings.”
///   • Open phone settings → os_settings
///   • Not now → back
/// API: —
class SfUnplugAuthDeniedScreen extends StatelessWidget {
  const SfUnplugAuthDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Unplug', pill: 'Step 1 of 3'),
      children: [
        TBanner(kind: TBannerKind.info, text: 'Screen Time access was not allowed.'),
        TTitle('Unplug needs Screen Time to pause apps.'),
        TBody('Everything else in ScrollFree works without it: your goal, Pause 60 and check-ins.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Try again', onPressed: () => TNav.branch(context, 'Screen Time authorization (iOS Family Controls, individual)', <String, VoidCallback>{'Approved': () => TNav.replace(context, Routes.sfUnplugApps), 'Denied': () => TNav.toast(context, 'Still not allowed. You can turn it on later in Settings.')}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Open phone settings', onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
        TLink(key: const ValueKey('a:footer[2]'), label: 'Not now', onTap: () => TNav.back(context)),
      ],
    );
  }
}
