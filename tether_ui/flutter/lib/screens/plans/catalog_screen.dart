// GENERATED from spec/screens/catalog.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Add a program  ·  route `/programs`  ·  flow `plans`  ·  kind `screen`
/// Default state · phase welcome
/// Catalog is served by the catalogue service so a program can launch without an app release.
///
/// Actions (generated from spec/screens/catalog.json):
///   • Back → back
///   • BreatheFree → push → bf_intro
///   • ScrollFree → push → sf_intro
///   • ClearAir → push → ca_intro
///   • Heartwise → push → hw_intro
///   • Steady → push → st_intro
///   • Renew → push → re_intro
///   • Nourish → push → nu_intro
///   • Stride → push → sd_intro
///   • Ease → push → ea_intro
///   • Checkup → push → ck_intro
///   • Beacon → push → be_intro
/// API: —
class CatalogScreen extends StatelessWidget {
  const CatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'All programs'),
      children: [
        TTitle('Choose what you want support with.'),
        TListGroup(title: 'Quit · Manage', rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'BreatheFree', sub: 'Tobacco & nicotine · Quit / Reduce', lead: TLead.program('bf'), onTap: () => TNav.push(context, Routes.bfIntro)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'ScrollFree', sub: 'Social media use · Quit / Reduce', lead: TLead.program('sf'), onTap: () => TNav.push(context, Routes.sfIntro)), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: 'ClearAir', sub: 'Respiratory health · Manage', lead: TLead.program('ca'), onTap: () => TNav.push(context, Routes.caIntro)), TListRow(key: const ValueKey('a:body[1].rows[3]'), label: 'Heartwise', sub: 'Cardiovascular health · Manage', lead: TLead.program('hw'), onTap: () => TNav.push(context, Routes.hwIntro)), TListRow(key: const ValueKey('a:body[1].rows[4]'), label: 'Steady', sub: 'Diabetes & metabolic health · Manage', lead: TLead.program('st'), onTap: () => TNav.push(context, Routes.stIntro)), TListRow(key: const ValueKey('a:body[1].rows[5]'), label: 'Renew', sub: 'Kidney & liver health · Manage', lead: TLead.program('re'), onTap: () => TNav.push(context, Routes.reIntro))]),
        TListGroup(title: 'Habits · Support · Prevent', rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Nourish', sub: 'Obesity & nutrition · Build habits', lead: TLead.program('nu'), onTap: () => TNav.push(context, Routes.nuIntro)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Stride', sub: 'Healthy aging · Build habits', lead: TLead.program('sd'), onTap: () => TNav.push(context, Routes.sdIntro)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Ease', sub: 'Mental & behavioral health · Support', lead: TLead.program('ea'), onTap: () => TNav.push(context, Routes.eaIntro)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Checkup', sub: 'Preventive health · Prevent', lead: TLead.program('ck'), onTap: () => TNav.push(context, Routes.ckIntro)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: 'Beacon', sub: 'Cancer · Prevent', lead: TLead.program('be'), onTap: () => TNav.push(context, Routes.beIntro))]),
      ],
    );
  }
}
