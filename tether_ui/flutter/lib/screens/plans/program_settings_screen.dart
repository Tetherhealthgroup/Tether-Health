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
    return TScreen(
      header: THeader(title: 'BreatheFree settings'),
      children: [
        TListGroup(flat: true, rows: [TListRow(label: 'BreatheFree', sub: 'Focus since Aug 14', lead: TLead.program('bf'))]),
        TRadioList(fieldKey: 'program_settings.status', items: [TRadioItem('Focus', sub: 'Daily steps and reminders'), TRadioItem('Learn only', sub: 'Keep lessons, stop tracking'), TRadioItem('Pause', sub: 'Stop reminders; keep everything')], selected: 0, label: 'Status', bind: 'enrolment.status'),
        TCard(eyebrow: 'Sharing', children: [TToggleRow(fieldKey: 'program_settings.care_team_sharing', label: 'Care team · Dr. Patel’s clinic', sub: 'Manual: you approve each summary', value: true, bind: 'enrolment.care_team_sharing'), TToggleRow(fieldKey: 'program_settings.de_identified_research', label: 'De-identified research', bind: 'enrolment.de_identified_research')]),
        TListGroup(title: 'Data', rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Export BreatheFree data', sub: 'PDF + JSON', onTap: () => TNav.toast(context, 'Export is being prepared. We’ll notify you.')), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'Leave BreatheFree', sub: 'Keep your data or delete it now', danger: true, onTap: () => TNav.sheet(context, Routes.accountLeave))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save changes', onPressed: () => TNav.submit(context, 'PATCH /v1/enrolments/:id', screenId: 'program_settings', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
