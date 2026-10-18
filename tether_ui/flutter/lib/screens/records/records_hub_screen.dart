// GENERATED from spec/screens/records_hub.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Health records  ·  route `/records`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_hub.json):
///   • Back → back
///   • Patel Family Medicine → push → records_source
///   • Medicare → push → records_source
///   • Blood pressure → push → records_item
///   • Lab results → push → records_item
///   • Immunizations → push → records_item
///   • Smoking status → push → records_item
///   • Medications & conditions → push → records_item
///   • 2 items need your review → push → records_conflict
///   • Add a source → push → records_add
///   • Enter a value manually → push → records_manual
/// API: GET /v1/records/fhir/sources, GET /v1/records/fhir/summary
class RecordsHubScreen extends StatelessWidget {
  const RecordsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Health records'),
      children: [
        TBanner(kind: TBannerKind.info, text: 'Read-only. Tether never writes to your health record, and each program only gets the data it needs.'),
        TListGroup(title: 'Connected sources', rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'Patel Family Medicine', sub: 'Epic MyChart · synced today 7:02 AM', lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsSource)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'Medicare', sub: 'Blue Button 2.0 · synced Oct 12', lead: TLead.icon('M'), onTap: () => TNav.push(context, Routes.recordsSource))]),
        TListGroup(title: 'Imported data', rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Blood pressure', sub: '12 readings · Heartwise', onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Lab results', sub: 'A1C, lipids, eGFR · Steady, Heartwise, Renew', onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Immunizations', sub: '6 · Checkup', onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Smoking status', sub: 'Every day smoker (Aug 2026) · BreatheFree', onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: 'Medications & conditions', sub: 'Shown for reference only', onTap: () => TNav.push(context, Routes.recordsItem))]),
        TCard(key: const ValueKey('a:body[3]'), variant: TCardVariant.warn, title: '2 items need your review', text: 'A value that differs from what you entered, and one that looks like a typo.', onTap: () => TNav.push(context, Routes.recordsConflict)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Add a source', onPressed: () => TNav.push(context, Routes.recordsAdd), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Enter a value manually', onPressed: () => TNav.push(context, Routes.recordsManual), variant: TButtonVariant.secondary),
      ],
    );
  }
}
