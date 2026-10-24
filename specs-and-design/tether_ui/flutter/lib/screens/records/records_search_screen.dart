// GENERATED from spec/screens/records_search.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Find your provider  ·  route `/records/search`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// Directory built from Epic’s published patient-facing FHIR endpoints plus partner registries.
///
/// Actions (generated from spec/screens/records_search.json):
///   • Back → back
///   • Patel Family Medicine → push → records_consent
///   • Patel Heart Institute → push → records_consent
///   • Stanford Health Care → push → records_consent
///   • Can’t find it? Enter a FHIR address → push → records_fhir_url
/// API: GET /v1/records/fhir/directory?q=
class RecordsSearchScreen extends StatelessWidget {
  const RecordsSearchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsSearchHeaderTitle),
      children: [
        TField(fieldKey: 'records_search.query', label: s.recordsSearchBodyN0Label, placeholder: s.recordsSearchBodyN0Placeholder, kind: TFieldKind.search),
        TListGroup(title: s.recordsSearchBodyN1Title, rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: s.recordsSearchBodyN1RowsN0Label, sub: s.recordsSearchBodyN1RowsN0Sub, lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsConsent)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: s.recordsSearchBodyN1RowsN1Label, sub: s.recordsSearchBodyN1RowsN1Sub, lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsConsent)), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: s.recordsSearchBodyN1RowsN2Label, sub: s.recordsSearchBodyN1RowsN2Sub, lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsConsent))]),
        TLink(key: const ValueKey('a:body[2]'), label: s.recordsSearchBodyN2Label, onTap: () => TNav.push(context, Routes.recordsFhirUrl)),
      ],
    );
  }
}
