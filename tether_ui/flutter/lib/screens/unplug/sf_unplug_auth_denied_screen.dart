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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Unplug', pill: s.sfUnplugAuthDeniedHeaderPill),
      children: [
        TBanner(kind: TBannerKind.info, text: s.sfUnplugAuthDeniedBodyN0Text),
        TTitle(s.sfUnplugAuthDeniedBodyN1Text),
        TBody(s.sfUnplugAuthDeniedBodyN2Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugAuthDeniedFooterN0Label, onPressed: () => TNav.branch(context, 'Screen Time authorization (iOS Family Controls, individual)', <String, VoidCallback>{'Approved': () => TNav.replace(context, Routes.sfUnplugApps), 'Denied': () => TNav.toast(context, s.sfUnplugAuthDeniedFooterN0ActionCasesN1ActionValue)}, device: const TBranchRef('unplug.setup.ios_authorization_retry', TAsk.unplugAuthIos, 'sf_unplug_auth_denied'), when: const <TAnswer, String>{TAnswer.granted: 'Approved', TAnswer.grantedNotificationsOff: 'Approved', TAnswer.denied: 'Denied', TAnswer.unavailable: 'Denied'}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugAuthDeniedFooterN1Label, onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
        TLink(key: const ValueKey('a:footer[2]'), label: s.sfUnplugAuthDeniedFooterN2Label, onTap: () => TNav.back(context)),
      ],
    );
  }
}
