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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.catalogHeaderTitle),
      children: [
        TTitle(s.catalogBodyN0Text),
        TListGroup(title: s.catalogBodyN1Title, rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'BreatheFree', sub: s.catalogBodyN1RowsN0Sub, lead: TLead.program('bf'), onTap: () => TNav.push(context, Routes.bfIntro)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'ScrollFree', sub: s.catalogBodyN1RowsN1Sub, lead: TLead.program('sf'), onTap: () => TNav.push(context, Routes.sfIntro)), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: 'ClearAir', sub: s.catalogBodyN1RowsN2Sub, lead: TLead.program('ca'), onTap: () => TNav.push(context, Routes.caIntro)), TListRow(key: const ValueKey('a:body[1].rows[3]'), label: 'Heartwise', sub: s.catalogBodyN1RowsN3Sub, lead: TLead.program('hw'), onTap: () => TNav.push(context, Routes.hwIntro)), TListRow(key: const ValueKey('a:body[1].rows[4]'), label: 'Steady', sub: s.catalogBodyN1RowsN4Sub, lead: TLead.program('st'), onTap: () => TNav.push(context, Routes.stIntro)), TListRow(key: const ValueKey('a:body[1].rows[5]'), label: 'Renew', sub: s.catalogBodyN1RowsN5Sub, lead: TLead.program('re'), onTap: () => TNav.push(context, Routes.reIntro))]),
        TListGroup(title: s.catalogBodyN2Title, rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Nourish', sub: s.catalogBodyN2RowsN0Sub, lead: TLead.program('nu'), onTap: () => TNav.push(context, Routes.nuIntro)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Stride', sub: s.catalogBodyN2RowsN1Sub, lead: TLead.program('sd'), onTap: () => TNav.push(context, Routes.sdIntro)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Ease', sub: s.catalogBodyN2RowsN2Sub, lead: TLead.program('ea'), onTap: () => TNav.push(context, Routes.eaIntro)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Checkup', sub: s.catalogBodyN2RowsN3Sub, lead: TLead.program('ck'), onTap: () => TNav.push(context, Routes.ckIntro)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: 'Beacon', sub: s.catalogBodyN2RowsN4Sub, lead: TLead.program('be'), onTap: () => TNav.push(context, Routes.beIntro))]),
      ],
    );
  }
}
