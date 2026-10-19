// GENERATED from spec/screens/program_settings_sf.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Program settings · ScrollFree with Unplug  ·  route `/p/:program/settings?state=sf-unplug`  ·  flow `plans`  ·  kind `screen`
/// State: ScrollFree of program_settings · phase account
/// Copy needs clinical/legal review. The ScrollFree instance of the parameterized Program settings (the base screen is shown with BreatheFree data). Only ScrollFree has the Screen Time & Unplug section. Leaving ScrollFree or deleting the account also runs purgeLocalData(0).
///
/// Actions (generated from spec/screens/program_settings_sf.json):
///   • Back → back
///   • Unplug → push → sf_unplug_home
///   • Screen Time access → push → sf_screentime
///   • Turn off Unplug or Screen Time → sheet → sf_unplug_off
///   • Export ScrollFree data → toast “Export is being prepared. We’ll notify you.”
///   • Leave ScrollFree → sheet → account_leave
///   • Save changes → PATCH /v1/enrolments/:id then toast “Saved” then back
/// API: PATCH /v1/enrolments/:id
class ProgramSettingsSfScreen extends StatelessWidget {
  const ProgramSettingsSfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'ScrollFree settings'),
      children: [
        TListGroup(flat: true, rows: [TListRow(label: 'ScrollFree', sub: 'Focus since Aug 14', lead: TLead.program('sf'))]),
        TRadioList(fieldKey: 'program_settings_sf.status', items: [TRadioItem('Focus', sub: 'Daily steps and reminders'), TRadioItem('Learn only', sub: 'Keep lessons, stop tracking'), TRadioItem('Pause', sub: 'Stop reminders; keep everything')], selected: 0, label: 'Status'),
        TCard(eyebrow: 'Sharing', children: [TToggleRow(fieldKey: 'program_settings_sf.care_team_sharing', label: 'Care team sharing', sub: 'Off · ScrollFree isn’t shared'), TToggleRow(fieldKey: 'program_settings_sf.de_identified_research', label: 'De-identified research')]),
        TListGroup(title: 'Screen Time & Unplug', rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Unplug', sub: 'On · 2 groups · 60 min limit', onTap: () => TNav.push(context, Routes.sfUnplugHome)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'Screen Time access', sub: 'Connected · totals only', onTap: () => TNav.push(context, Routes.sfScreentime)), TListRow(key: const ValueKey('a:body[3].rows[2]'), label: 'Turn off Unplug or Screen Time', sub: 'Anytime', danger: true, onTap: () => TNav.sheet(context, Routes.sfUnplugOff))]),
        TListGroup(title: 'Data', rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: 'Export ScrollFree data', sub: 'PDF + JSON', onTap: () => TNav.toast(context, 'Export is being prepared. We’ll notify you.')), TListRow(key: const ValueKey('a:body[4].rows[1]'), label: 'Leave ScrollFree', sub: 'Keep your data or delete it now', danger: true, onTap: () => TNav.sheet(context, Routes.accountLeave))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save changes', onPressed: () => TNav.submit(context, 'PATCH /v1/enrolments/:id', screenId: 'program_settings_sf', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
