// GENERATED from spec/screens/sf_unplug_session_done.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Session complete  ·  route `/p/sf/unplug/session/done`  ·  flow `unplug`  ·  kind `screen`
/// Default state · program sf · phase milestone
/// Copy needs clinical/legal review. Opened from the session-finished notification (generic text) or when the timer ends in the app.
///
/// Actions (generated from spec/screens/sf_unplug_session_done.json):
///   • Done → replace → sf_unplug_home
/// API: —
class SfUnplugSessionDoneScreen extends StatelessWidget {
  const SfUnplugSessionDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Focus session', left: THeaderLeft.none),
      children: [
        TIllustration(glyph: '✓'),
        TBigNumber(value: '45', unit: 'min', caption: 'Session complete · your apps are open again', center: true),
        TBody('Want to make this a habit? You can start one from ScrollFree anytime.', tone: TTextTone.muted, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Done', onPressed: () => TNav.replace(context, Routes.sfUnplugHome), arrow: true),
      ],
    );
  }
}
