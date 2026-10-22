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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugSessionDoneEarlyHeaderTitle, left: THeaderLeft.none),
      children: [
        TBigNumber(value: '18', unit: 'min', caption: s.sfUnplugSessionDoneEarlyBodyN0Caption, center: true),
        TKeyValue(rows: [(s.sfUnplugSessionDoneEarlyBodyN1RowsN0N0, s.sfUnplugSessionDoneEarlyBodyN1RowsN0N1), (s.sfUnplugSessionDoneEarlyBodyN1RowsN1N0, s.sfUnplugSessionDoneEarlyBodyN1RowsN1N1)]),
        TBody(s.sfUnplugSessionDoneEarlyBodyN2Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugSessionDoneEarlyFooterN0Label, onPressed: () => TNav.replace(context, Routes.sfUnplugHome), arrow: true),
      ],
    );
  }
}
