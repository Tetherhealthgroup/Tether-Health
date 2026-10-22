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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.programSettingsSfHeaderTitle),
      children: [
        TListGroup(flat: true, rows: [TListRow(label: 'ScrollFree', sub: s.programSettingsSfBodyN0RowsN0Sub, lead: TLead.program('sf'))]),
        TRadioList(fieldKey: 'program_settings_sf.status', items: [TRadioItem(s.programSettingsSfBodyN1ItemsN0Label, value: 'Focus', sub: s.programSettingsSfBodyN1ItemsN0Sub), TRadioItem(s.programSettingsSfBodyN1ItemsN1Label, value: 'Learn only', sub: s.programSettingsSfBodyN1ItemsN1Sub), TRadioItem(s.programSettingsSfBodyN1ItemsN2Label, value: 'Pause', sub: s.programSettingsSfBodyN1ItemsN2Sub)], selected: 0, label: s.programSettingsSfBodyN1Label, bind: 'enrolment.:program.status'),
        TCard(eyebrow: s.programSettingsSfBodyN2Eyebrow, children: [TToggleRow(fieldKey: 'program_settings_sf.care_team_sharing', label: s.programSettingsSfBodyN2ChildrenN0Label, sub: s.programSettingsSfBodyN2ChildrenN0Sub, bind: 'enrolment.:program.care_team_sharing'), TToggleRow(fieldKey: 'program_settings_sf.de_identified_research', label: s.programSettingsSfBodyN2ChildrenN1Label, bind: 'enrolment.:program.de_identified_research')]),
        TListGroup(title: s.programSettingsSfBodyN3Title, rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Unplug', sub: s.programSettingsSfBodyN3RowsN0Sub, onTap: () => TNav.push(context, Routes.sfUnplugHome)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: s.programSettingsSfBodyN3RowsN1Label, sub: s.programSettingsSfBodyN3RowsN1Sub, onTap: () => TNav.push(context, Routes.sfScreentime)), TListRow(key: const ValueKey('a:body[3].rows[2]'), label: s.programSettingsSfBodyN3RowsN2Label, sub: s.programSettingsSfBodyN3RowsN2Sub, danger: true, onTap: () => TNav.sheet(context, Routes.sfUnplugOff))]),
        TListGroup(title: s.programSettingsSfBodyN4Title, rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: s.programSettingsSfBodyN4RowsN0Label, sub: s.programSettingsSfBodyN4RowsN0Sub, onTap: () => TNav.toast(context, s.programSettingsSfBodyN4RowsN0ActionValue)), TListRow(key: const ValueKey('a:body[4].rows[1]'), label: s.programSettingsSfBodyN4RowsN1Label, sub: s.programSettingsSfBodyN4RowsN1Sub, danger: true, onTap: () => TNav.sheet(context, Routes.accountLeave))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.programSettingsSfFooterN0Label, onPressed: () => TNav.submit(context, 'PATCH /v1/enrolments/:id', screenId: 'program_settings_sf', then: () => TNav.toast(context, s.programSettingsSfFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
