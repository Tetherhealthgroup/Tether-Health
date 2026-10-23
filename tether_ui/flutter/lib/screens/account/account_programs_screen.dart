// GENERATED from spec/screens/account_programs.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Programs & sharing  ·  route `/account/programs`  ·  flow `account`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/account_programs.json):
///   • Back → back
///   • BreatheFree → push → program_settings
///   • ScrollFree → push → program_settings
///   • ClearAir → push → program_settings
///   • Heartwise → push → program_settings
///   • Add a program → push → catalog
/// API: —
class AccountProgramsScreen extends StatelessWidget {
  const AccountProgramsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.accountProgramsHeaderTitle),
      children: [
        TBoundValues(keys: const ['account.focus_slots'], place: TExamplePlace.inline, builder: (context, v) => TBody(v.text('account.focus_slots', s.accountProgramsBodyN0Text), tone: TTextTone.small)),
        TBoundValues(keys: const ['enrolment.bf.summary', 'enrolment.sf.summary', 'enrolment.ca.summary', 'enrolment.hw.summary'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'BreatheFree', sub: v.text('enrolment.bf.summary', s.accountProgramsBodyN1RowsN0Sub), lead: TLead.program('bf'), onTap: () => TNav.push(context, Routes.programSettings, program: 'bf')), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'ScrollFree', sub: v.text('enrolment.sf.summary', s.accountProgramsBodyN1RowsN1Sub), lead: TLead.program('sf'), onTap: () => TNav.push(context, Routes.programSettings, program: 'sf')), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: 'ClearAir', sub: v.text('enrolment.ca.summary', s.accountProgramsBodyN1RowsN2Sub), lead: TLead.program('ca'), onTap: () => TNav.push(context, Routes.programSettings, program: 'ca')), TListRow(key: const ValueKey('a:body[1].rows[3]'), label: 'Heartwise', sub: v.text('enrolment.hw.summary', s.accountProgramsBodyN1RowsN3Sub), lead: TLead.program('hw'), onTap: () => TNav.push(context, Routes.programSettings, program: 'hw'))])),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.accountProgramsFooterN0Label, onPressed: () => TNav.push(context, Routes.catalog), variant: TButtonVariant.secondary),
      ],
    );
  }
}
