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
    return TScreen(
      header: THeader(title: 'Tracking check'),
      children: [
        TBanner(kind: TBannerKind.error, text: 'Unplug has stopped. Nothing is being counted or paused until this is fixed.'),
        TChecklist(items: [TCheckItem('Screen Time permission', sub: 'Turned off in Settings'), TCheckItem('Daily schedule', sub: 'Running', done: true), TCheckItem('Settings shared with the pause screen', sub: 'Ready', done: true)], label: 'iPhone checks'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Open phone settings', onPressed: () => TNav.osSettings(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Check again', onPressed: () => TNav.branch(context, 'Tracking health result', <String, VoidCallback>{'All pass': () => TNav.replace(context, Routes.sfUnplugHealth), 'Still failing': () => TNav.toast(context, 'Still not working. Turn Screen Time access on again in Settings.')}), variant: TButtonVariant.secondary),
      ],
    );
  }
}
