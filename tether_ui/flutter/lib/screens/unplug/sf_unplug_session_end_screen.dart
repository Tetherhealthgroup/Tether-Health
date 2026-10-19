// GENERATED from spec/screens/sf_unplug_session_end.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// End session early  ·  route `/p/sf/unplug/session/end`  ·  flow `unplug`  ·  kind `sheet`
/// Default state · program sf · phase rescue
/// Copy needs clinical/legal review. End session works only after a reason is chosen or typed (rule sf.unplug.reason).
///
/// Actions (generated from spec/screens/sf_unplug_session_end.json):
///   • End session → decide sf.unplug.reason: Strict session: reason given? → Reason given: CALL device:unplug/endSession then replace → sf_unplug_session_done_early | No reason yet: toast “Choose or type a reason to end a strict session.”
///   • Keep going → close
/// API: —
class SfUnplugSessionEndScreen extends StatelessWidget {
  const SfUnplugSessionEndScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      children: [
        TTitle('End your session early?'),
        TBody('This is a strict session. Choose or type a reason; it is kept with the session on this phone. Nothing resets.', tone: TTextTone.muted),
        TChips(fieldKey: 'sf_unplug_session_end.reason', options: ['Need an app for work', 'Expecting a message', 'Changed my mind', 'Other'], multi: false, label: 'Reason'),
        TField(fieldKey: 'sf_unplug_session_end.note', label: 'Anything to add?', placeholder: 'Optional', kind: TFieldKind.multiline),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'End session', onPressed: () => TNav.branch(context, 'Strict session: reason given?', <String, VoidCallback>{'Reason given': () => TNav.submit(context, 'CALL device:unplug/endSession', screenId: 'sf_unplug_session_end', then: () => TNav.replace(context, Routes.sfUnplugSessionDoneEarly)), 'No reason yet': () => TNav.toast(context, 'Choose or type a reason to end a strict session.')}, decide: 'sf.unplug.reason'), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Keep going', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
