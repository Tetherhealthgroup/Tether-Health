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
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TTitle(s.sfUnplugSessionEndBodyN0Text),
        TBody(s.sfUnplugSessionEndBodyN1Text, tone: TTextTone.muted),
        TChips(fieldKey: 'sf_unplug_session_end.reason', options: ['Need an app for work', 'Expecting a message', 'Changed my mind', 'Other'], labels: [s.sfUnplugSessionEndBodyN2OptionsN0, s.sfUnplugSessionEndBodyN2OptionsN1, s.sfUnplugSessionEndBodyN2OptionsN2, s.sfUnplugSessionEndBodyN2OptionsN3], multi: false, label: s.sfUnplugSessionEndBodyN2Label),
        TField(fieldKey: 'sf_unplug_session_end.note', label: s.sfUnplugSessionEndBodyN3Label, placeholder: s.sfUnplugSessionEndBodyN3Placeholder, kind: TFieldKind.multiline),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugSessionEndFooterN0Label, onPressed: () => TNav.branch(context, 'Strict session: reason given?', <String, VoidCallback>{'Reason given': () => TNav.submit(context, 'CALL device:unplug/endSession', screenId: 'sf_unplug_session_end', then: () => TNav.replace(context, Routes.sfUnplugSessionDoneEarly)), 'No reason yet': () => TNav.toast(context, s.sfUnplugSessionEndFooterN0ActionCasesN1ActionValue)}, decide: 'sf.unplug.reason'), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugSessionEndFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
