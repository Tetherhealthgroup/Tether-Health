// GENERATED from spec/screens/records_add.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Add a source  ·  route `/records/add`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_add.json):
///   • Back → back
///   • Hospital or clinic → push → records_search
///   • Oracle Health (Cerner) → push → records_search
///   • Medicare · Blue Button 2.0 → push → records_consent_bb
///   • Apple Health Records → push → records_consent_device
///   • Health Connect → push → records_consent_device
///   • Other FHIR server → push → records_fhir_url
///   • Enter manually → push → records_manual
/// API: —
class RecordsAddScreen extends StatelessWidget {
  const RecordsAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsAddHeaderTitle),
      children: [
        TTitle(s.recordsAddBodyN0Text),
        TBody(s.recordsAddBodyN1Text, tone: TTextTone.muted),
        TListGroup(title: s.recordsAddBodyN2Title, rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.recordsAddBodyN2RowsN0Label, sub: s.recordsAddBodyN2RowsN0Sub, lead: TLead.icon('E'), onTap: () => TNav.push(context, Routes.recordsSearch)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Oracle Health (Cerner)', sub: s.recordsAddBodyN2RowsN1Sub, lead: TLead.icon('O'), onTap: () => TNav.push(context, Routes.recordsSearch)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.recordsAddBodyN2RowsN2Label, sub: s.recordsAddBodyN2RowsN2Sub, lead: TLead.icon('M'), onTap: () => TNav.push(context, Routes.recordsConsentBb)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Apple Health Records', sub: s.recordsAddBodyN2RowsN3Sub, lead: TLead.icon(''), onTap: () => TNav.push(context, Routes.recordsConsentDevice)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: 'Health Connect', sub: s.recordsAddBodyN2RowsN4Sub, lead: TLead.icon('H'), onTap: () => TNav.push(context, Routes.recordsConsentDevice)), TListRow(key: const ValueKey('a:body[2].rows[5]'), label: s.recordsAddBodyN2RowsN5Label, sub: s.recordsAddBodyN2RowsN5Sub, lead: TLead.icon('F'), onTap: () => TNav.push(context, Routes.recordsFhirUrl))]),
        TListGroup(title: s.recordsAddBodyN3Title, rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: s.recordsAddBodyN3RowsN0Label, sub: s.recordsAddBodyN3RowsN0Sub, lead: TLead.icon('+'), onTap: () => TNav.push(context, Routes.recordsManual))]),
        TBody(s.recordsAddBodyN4Text, tone: TTextTone.small),
      ],
    );
  }
}
