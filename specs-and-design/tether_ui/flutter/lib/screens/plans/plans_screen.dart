// GENERATED from spec/screens/plans.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// My plans  ·  route `/plans`  ·  flow `plans`  ·  kind `screen`
/// Default state · phase plan
/// 
///
/// Actions (generated from spec/screens/plans.json):
///   • Avatar · Account → push → account
///   • BreatheFree → push → bf_home
///   • ScrollFree → push → sf_home
///   • ClearAir → push → ca_intro
///   • Medication center → push → bf_meds
///   • Programs & sharing → push → account_programs
///   • Add a program → push → catalog
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class PlansScreen extends StatelessWidget {
  const PlansScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.plansHeaderTitle, left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TBoundValues(keys: const ['bf.plan_summary', 'sf.plan_summary', 'plans.focus_heading'], builder: (context, v) => TListGroup(title: v.text('plans.focus_heading', s.plansBodyN0Title), rows: [TListRow(key: const ValueKey('a:body[0].rows[0]'), label: 'BreatheFree', sub: v.text('bf.plan_summary', s.plansBodyN0RowsN0Sub), lead: TLead.program('bf'), pill: s.plansBodyN0RowsN0Pill, onTap: () => TNav.push(context, Routes.bfHome)), TListRow(key: const ValueKey('a:body[0].rows[1]'), label: 'ScrollFree', sub: v.text('sf.plan_summary', s.plansBodyN0RowsN1Sub), lead: TLead.program('sf'), pill: s.plansBodyN0RowsN1Pill, onTap: () => TNav.push(context, Routes.sfHome))])),
        TListGroup(title: s.plansBodyN1Title, rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'ClearAir', sub: s.plansBodyN1RowsN0Sub, lead: TLead.program('ca'), pill: s.plansBodyN1RowsN0Pill, onTap: () => TNav.push(context, Routes.caIntro))]),
        TBoundValues(keys: const ['plans.medication_summary'], builder: (context, v) => TListGroup(title: s.plansBodyN2Title, rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.plansBodyN2RowsN0Label, sub: v.text('plans.medication_summary', s.plansBodyN2RowsN0Sub), onTap: () => TNav.push(context, Routes.bfMeds)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.plansBodyN2RowsN1Label, sub: s.plansBodyN2RowsN1Sub, onTap: () => TNav.push(context, Routes.accountPrograms))])),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.plansFooterN0Label, onPressed: () => TNav.push(context, Routes.catalog), variant: TButtonVariant.secondary),
      ],
    );
  }
}
