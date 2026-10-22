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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugSessionHeaderTitle),
      children: [
        TTitle(s.sfUnplugSessionBodyN0Text),
        TChips(fieldKey: 'sf_unplug_session.duration', options: ['25 min', '45 min', '60 min', '90 min'], labels: [s.sfUnplugSessionBodyN1OptionsN0, s.sfUnplugSessionBodyN1OptionsN1, s.sfUnplugSessionBodyN1OptionsN2, s.sfUnplugSessionBodyN1OptionsN3], selected: ['45 min'], multi: false, label: s.sfUnplugSessionBodyN1Label),
        TRadioList(fieldKey: 'sf_unplug_session.scope', items: [TRadioItem(s.sfUnplugSessionBodyN2ItemsN0Label, value: 'Only my chosen apps', sub: s.sfUnplugSessionBodyN2ItemsN0Sub), TRadioItem(s.sfUnplugSessionBodyN2ItemsN1Label, value: 'Everything except apps I allow', sub: s.sfUnplugSessionBodyN2ItemsN1Sub)], selected: 0, label: s.sfUnplugSessionBodyN2Label),
        TCard(children: [TToggleRow(fieldKey: 'sf_unplug_session.strict', label: s.sfUnplugSessionBodyN3ChildrenN0Label, sub: s.sfUnplugSessionBodyN3ChildrenN0Sub)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugSessionFooterN0Label, onPressed: () => TNav.submit(context, 'CALL device:unplug/startSession', screenId: 'sf_unplug_session', then: () => TNav.replace(context, Routes.sfUnplugSessionActive)), arrow: true),
      ],
    );
  }
}
