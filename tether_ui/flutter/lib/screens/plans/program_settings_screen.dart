// GENERATED from spec/screens/program_settings.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Program settings  ·  route `/p/:program/settings`  ·  flow `plans`  ·  kind `screen`
/// Default state · phase account
/// Parameterized by program. Shown here with BreatheFree data.
///
/// Actions (generated from spec/screens/program_settings.json):
///   • Back → back
///   • Export BreatheFree data → toast “Export is being prepared. We’ll notify you.”
///   • Leave BreatheFree → sheet → account_leave
///   • Save changes → PATCH /v1/enrolments/:id then toast “Saved” then back
/// API: PATCH /v1/enrolments/:id
class ProgramSettingsScreen extends StatelessWidget {
  const ProgramSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.programSettingsHeaderTitle),
      children: [
        TBoundValues(keys: const ['enrolment.:program.since'], builder: (context, v) => TListGroup(flat: true, rows: [TListRow(label: 'BreatheFree', sub: v.text('enrolment.:program.since', s.programSettingsBodyN0RowsN0Sub), lead: TLead.program('bf'))])),
        TRadioList(fieldKey: 'program_settings.status', items: [TRadioItem(s.programSettingsBodyN1ItemsN0Label, value: 'Focus', sub: s.programSettingsBodyN1ItemsN0Sub), TRadioItem(s.programSettingsBodyN1ItemsN1Label, value: 'Learn only', sub: s.programSettingsBodyN1ItemsN1Sub), TRadioItem(s.programSettingsBodyN1ItemsN2Label, value: 'Pause', sub: s.programSettingsBodyN1ItemsN2Sub)], selected: 0, label: s.programSettingsBodyN1Label, bind: 'enrolment.:program.status'),
        TCard(eyebrow: s.programSettingsBodyN2Eyebrow, children: [TToggleRow(fieldKey: 'program_settings.care_team_sharing', label: s.programSettingsBodyN2ChildrenN0Label, sub: s.programSettingsBodyN2ChildrenN0Sub, value: true, bind: 'enrolment.:program.care_team_sharing'), TToggleRow(fieldKey: 'program_settings.de_identified_research', label: s.programSettingsBodyN2ChildrenN1Label, bind: 'enrolment.:program.de_identified_research')]),
        TListGroup(title: s.programSettingsBodyN3Title, rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: s.programSettingsBodyN3RowsN0Label, sub: s.programSettingsBodyN3RowsN0Sub, onTap: () => TNav.toast(context, s.programSettingsBodyN3RowsN0ActionValue)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: s.programSettingsBodyN3RowsN1Label, sub: s.programSettingsBodyN3RowsN1Sub, danger: true, onTap: () => TNav.sheet(context, Routes.accountLeave))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.programSettingsFooterN0Label, onPressed: () => TNav.submit(context, 'PATCH /v1/enrolments/:id', screenId: 'program_settings', then: () => TNav.toast(context, s.programSettingsFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
