// GENERATED from spec/screens/sf_unplug_session.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Start a focus session  ·  route `/p/sf/unplug/session`  ·  flow `unplug`  ·  kind `screen`
/// Default state · program sf · phase rescue
/// Copy needs clinical/legal review. Device-only. Tether (and so Rescue and 988), the phone dialer and emergency calling are never paused.
///
/// Actions (generated from spec/screens/sf_unplug_session.json):
///   • Back → back
///   • Start session → CALL device:unplug/startSession then replace → sf_unplug_session_active
/// API: —
class SfUnplugSessionScreen extends StatelessWidget {
  const SfUnplugSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Focus session'),
      children: [
        TTitle('Pause your apps for a while.'),
        TChips(fieldKey: 'sf_unplug_session.duration', options: ['25 min', '45 min', '60 min', '90 min'], selected: ['45 min'], multi: false, label: 'How long'),
        TRadioList(fieldKey: 'sf_unplug_session.scope', items: [TRadioItem('Only my chosen apps', sub: 'Video apps, Feeds'), TRadioItem('Everything except apps I allow', sub: 'Tether, phone calls and emergency calls always stay open')], selected: 0, label: 'What to pause'),
        TCard(children: [TToggleRow(fieldKey: 'sf_unplug_session.strict', label: 'Strict', sub: 'Ending early asks for a reason, kept on this phone')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Start session', onPressed: () => TNav.submit(context, 'CALL device:unplug/startSession', then: () => TNav.replace(context, Routes.sfUnplugSessionActive)), arrow: true),
      ],
    );
  }
}
