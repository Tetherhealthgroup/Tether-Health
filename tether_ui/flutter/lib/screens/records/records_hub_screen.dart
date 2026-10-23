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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsHubHeaderTitle),
      children: [
        TBanner(kind: TBannerKind.info, text: s.recordsHubBodyN0Text),
        TBoundValues(keys: const ['records.source_1.name', 'records.source_1.status', 'records.source_2.name', 'records.source_2.status'], builder: (context, v) => TListGroup(title: s.recordsHubBodyN1Title, rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: v.text('records.source_1.name', s.recordsHubBodyN1RowsN0Label), sub: v.text('records.source_1.status', s.recordsHubBodyN1RowsN0Sub), lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsSource)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: v.text('records.source_2.name', 'Medicare'), sub: v.text('records.source_2.status', s.recordsHubBodyN1RowsN1Sub), lead: TLead.icon('M'), onTap: () => TNav.push(context, Routes.recordsSource))])),
        TBoundValues(keys: const ['records.imported.blood_pressure', 'records.imported.labs', 'records.imported.immunizations', 'records.imported.smoking_status'], builder: (context, v) => TListGroup(title: s.recordsHubBodyN2Title, rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.recordsHubBodyN2RowsN0Label, sub: v.text('records.imported.blood_pressure', s.recordsHubBodyN2RowsN0Sub), onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.recordsHubBodyN2RowsN1Label, sub: v.text('records.imported.labs', s.recordsHubBodyN2RowsN1Sub), onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.recordsHubBodyN2RowsN2Label, sub: v.text('records.imported.immunizations', s.recordsHubBodyN2RowsN2Sub), onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: s.recordsHubBodyN2RowsN3Label, sub: v.text('records.imported.smoking_status', s.recordsHubBodyN2RowsN3Sub), onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: s.recordsHubBodyN2RowsN4Label, sub: s.recordsHubBodyN2RowsN4Sub, onTap: () => TNav.push(context, Routes.recordsItem))])),
        TBoundValues(keys: const ['records.review_count'], builder: (context, v) => TCard(key: const ValueKey('a:body[3]'), variant: TCardVariant.warn, title: v.text('records.review_count', s.recordsHubBodyN3Title), text: s.recordsHubBodyN3Text, onTap: () => TNav.push(context, Routes.recordsConflict))),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsHubFooterN0Label, onPressed: () => TNav.push(context, Routes.recordsAdd), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.recordsHubFooterN1Label, onPressed: () => TNav.push(context, Routes.recordsManual), variant: TButtonVariant.secondary),
      ],
    );
  }
}
