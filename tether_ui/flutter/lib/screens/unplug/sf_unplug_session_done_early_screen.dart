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
        TBoundValues(keys: const ['sf.unplug.session_minutes'], place: TExamplePlace.inline, builder: (context, v) => TBigNumber(value: v.text('sf.unplug.session_minutes', '18'), unit: 'min', caption: s.sfUnplugSessionDoneEarlyBodyN0Caption, center: true)),
        TBoundValues(keys: const ['sf.unplug.end_reason'], builder: (context, v) => TKeyValue(rows: [(s.sfUnplugSessionDoneEarlyBodyN1RowsN0N0, v.text('sf.unplug.end_reason', s.sfUnplugSessionDoneEarlyBodyN1RowsN0N1)), (s.sfUnplugSessionDoneEarlyBodyN1RowsN1N0, s.sfUnplugSessionDoneEarlyBodyN1RowsN1N1)])),
        TBoundValues(keys: const ['sf.unplug.early_end_line'], place: TExamplePlace.inline, builder: (context, v) => TBody(v.text('sf.unplug.early_end_line', s.sfUnplugSessionDoneEarlyBodyN2Text), tone: TTextTone.muted)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugSessionDoneEarlyFooterN0Label, onPressed: () => TNav.replace(context, Routes.sfUnplugHome), arrow: true),
      ],
    );
  }
}
