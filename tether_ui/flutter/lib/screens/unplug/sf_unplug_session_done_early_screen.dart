// GENERATED from spec/screens/sf_unplug_session_done_early.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Session ended early  ·  route `/p/sf/unplug/session/done?state=early`  ·  flow `unplug`  ·  kind `screen`
/// State: ended early of sf_unplug_session_done · program sf · phase milestone
/// Copy needs clinical/legal review.
///
/// Actions (generated from spec/screens/sf_unplug_session_done_early.json):
///   • Done → replace → sf_unplug_home
/// API: —
class SfUnplugSessionDoneEarlyScreen extends StatelessWidget {
  const SfUnplugSessionDoneEarlyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Focus session', left: THeaderLeft.none),
      children: [
        TBigNumber(value: '18', unit: 'min', caption: 'Ended early · your apps are open again', center: true),
        TKeyValue(rows: [('Reason', 'Expecting a message'), ('Kept', 'On this phone only')]),
        TBody('Nothing resets. 18 focused minutes still count.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Done', onPressed: () => TNav.replace(context, Routes.sfUnplugHome), arrow: true),
      ],
    );
  }
}
