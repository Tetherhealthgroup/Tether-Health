// GENERATED from spec/screens/sf_unplug_health_stopped.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Tracking stopped  ·  route `/p/sf/unplug/health?state=stopped`  ·  flow `unplug`  ·  kind `screen`
/// State: tracking stopped of sf_unplug_health · program sf · phase daily
/// Copy needs clinical/legal review. Also opened from the "Unplug needs attention" notification (generic text, no program name).
///
/// Actions (generated from spec/screens/sf_unplug_health_stopped.json):
///   • Back → back
///   • Open phone settings → os_settings
///   • Check again → branch: Tracking health result → All pass: replace → sf_unplug_health | Still failing: toast “Still not working. Turn Screen Time access on again in Settings.”
/// API: —
class SfUnplugHealthStoppedScreen extends StatelessWidget {
  const SfUnplugHealthStoppedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugHealthStoppedHeaderTitle),
      children: [
        TBanner(kind: TBannerKind.error, text: s.sfUnplugHealthStoppedBodyN0Text),
        TChecklist(items: [TCheckItem(s.sfUnplugHealthStoppedBodyN1ItemsN0Label, value: 'Screen Time permission', sub: s.sfUnplugHealthStoppedBodyN1ItemsN0Sub), TCheckItem(s.sfUnplugHealthStoppedBodyN1ItemsN1Label, value: 'Daily schedule', sub: s.sfUnplugHealthStoppedBodyN1ItemsN1Sub, done: true), TCheckItem(s.sfUnplugHealthStoppedBodyN1ItemsN2Label, value: 'Settings shared with the pause screen', sub: s.sfUnplugHealthStoppedBodyN1ItemsN2Sub, done: true)], label: s.sfUnplugHealthStoppedBodyN1Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugHealthStoppedFooterN0Label, onPressed: () => TNav.osSettings(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugHealthStoppedFooterN1Label, onPressed: () => TNav.branch(context, 'Tracking health result', <String, VoidCallback>{'All pass': () => TNav.replace(context, Routes.sfUnplugHealth), 'Still failing': () => TNav.toast(context, s.sfUnplugHealthStoppedFooterN1ActionCasesN1ActionValue)}, device: const TBranchRef('unplug.health.tracking_check', TAsk.unplugTrackingCheck, 'sf_unplug_health_stopped'), when: const <TAnswer, String>{TAnswer.healthy: 'All pass', TAnswer.failing: 'Still failing'}), variant: TButtonVariant.secondary),
      ],
    );
  }
}
