// GENERATED from spec/screens/sf_unplug_auth.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Allow Screen Time  ·  route `/p/sf/unplug/permission`  ·  flow `unplug`  ·  kind `screen`
/// Default state · program sf · phase plan
/// Copy needs clinical/legal review. iPhone. Continue calls requestAuthorization(individual); Apple shows its own prompt. Then the app checks notification permission. approved → choose apps, approved with notifications off → notifications-off state, denied → denied state, unavailable → unavailable state.
///
/// Actions (generated from spec/screens/sf_unplug_auth.json):
///   • Back → back
///   • Continue → branch: Screen Time authorization (iOS Family Controls, individual) → Approved: replace → sf_unplug_apps | Approved · notifications off: replace → sf_unplug_auth_notifications | Denied: replace → sf_unplug_auth_denied | Unavailable: replace → sf_unplug_auth_unavailable
///   • Not now → back
/// API: —
class SfUnplugAuthScreen extends StatelessWidget {
  const SfUnplugAuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Unplug', pill: s.sfUnplugAuthHeaderPill),
      children: [
        TIllustration(glyph: '◷'),
        TTitle(s.sfUnplugAuthBodyN1Text, center: true),
        TBody(s.sfUnplugAuthBodyN2Text, tone: TTextTone.muted, center: true),
        TKeyValue(rows: [(s.sfUnplugAuthBodyN3RowsN0N0, s.sfUnplugAuthBodyN3RowsN0N1), (s.sfUnplugAuthBodyN3RowsN1N0, s.sfUnplugAuthBodyN3RowsN1N1), (s.sfUnplugAuthBodyN3RowsN2N0, s.sfUnplugAuthBodyN3RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugAuthFooterN0Label, onPressed: () => TNav.branch(context, 'Screen Time authorization (iOS Family Controls, individual)', <String, VoidCallback>{'Approved': () => TNav.replace(context, Routes.sfUnplugApps), 'Approved · notifications off': () => TNav.replace(context, Routes.sfUnplugAuthNotifications), 'Denied': () => TNav.replace(context, Routes.sfUnplugAuthDenied), 'Unavailable': () => TNav.replace(context, Routes.sfUnplugAuthUnavailable)}, device: const TBranchRef('unplug.setup.ios_authorization', TAsk.unplugAuthIos, 'sf_unplug_auth'), when: const <TAnswer, String>{TAnswer.granted: 'Approved', TAnswer.grantedNotificationsOff: 'Approved · notifications off', TAnswer.denied: 'Denied', TAnswer.unavailable: 'Unavailable'}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugAuthFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
