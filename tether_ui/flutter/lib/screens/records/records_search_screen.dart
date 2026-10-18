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
    return TScreen(
      header: THeader(title: 'Find your provider'),
      children: [
        TField(fieldKey: 'records_search.query', label: 'Search', value: 'Patel', placeholder: 'Search hospital, clinic or doctor', kind: TFieldKind.search),
        TListGroup(title: 'Results', rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'Patel Family Medicine', sub: 'Epic · San Jose, CA', lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsConsent)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'Patel Heart Institute', sub: 'Epic · Fremont, CA', lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsConsent)), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: 'Stanford Health Care', sub: 'Epic · Palo Alto, CA', lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsConsent))]),
        TLink(key: const ValueKey('a:body[2]'), label: 'Can’t find it? Enter a FHIR address', onTap: () => TNav.push(context, Routes.recordsFhirUrl)),
      ],
    );
  }
}
