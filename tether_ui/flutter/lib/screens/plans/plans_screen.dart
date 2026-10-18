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
    return TScreen(
      header: THeader(title: 'My plans', left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TListGroup(title: 'Focus · 2 of 2', rows: [TListRow(key: const ValueKey('a:body[0].rows[0]'), label: 'BreatheFree', sub: 'Quit date · Fri, Aug 28', lead: TLead.program('bf'), pill: 'Focus', onTap: () => TNav.push(context, Routes.bfHome)), TListRow(key: const ValueKey('a:body[0].rows[1]'), label: 'ScrollFree', sub: '90 min/day · bedtime 10 PM–7 AM', lead: TLead.program('sf'), pill: 'Focus', onTap: () => TNav.push(context, Routes.sfHome))]),
        TListGroup(title: 'Learn only', rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'ClearAir', sub: 'Learn only · no plan yet', lead: TLead.program('ca'), pill: 'Learn', onTap: () => TNav.push(context, Routes.caIntro))]),
        TListGroup(title: 'Manage', rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Medication center', sub: 'BreatheFree · nicotine patch', onTap: () => TNav.push(context, Routes.bfMeds)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Programs & sharing', sub: 'Status, consent, data', onTap: () => TNav.push(context, Routes.accountPrograms))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Add a program', onPressed: () => TNav.push(context, Routes.catalog), variant: TButtonVariant.secondary),
      ],
    );
  }
}
