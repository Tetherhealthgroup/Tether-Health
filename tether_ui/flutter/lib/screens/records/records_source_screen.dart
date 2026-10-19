// GENERATED from spec/screens/records_source.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Source details  ·  route `/records/source`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_source.json):
///   • Back → back
///   • Sync now → POST /v1/records/fhir/sources/:id/sync then toast “Synced · 2 new results”
///   • What we read → push → records_consent
///   • Disconnect → sheet → records_disconnect
/// API: —
class RecordsSourceScreen extends StatelessWidget {
  const RecordsSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Patel Family Medicine'),
      children: [
        TKeyValue(rows: [('Connection', 'Epic MyChart · SMART on FHIR R4'), ('Last sync', 'Today 7:02 AM'), ('Next sync', 'Tomorrow'), ('Access', 'Read-only · 6 categories'), ('Connected', 'Oct 3, 2026')]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'Sync now', onTap: () => TNav.submit(context, 'POST /v1/records/fhir/sources/:id/sync', screenId: 'records_source', then: () => TNav.toast(context, 'Synced · 2 new results'))), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'What we read', onTap: () => TNav.push(context, Routes.recordsConsent))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Disconnect', onPressed: () => TNav.sheet(context, Routes.recordsDisconnect), variant: TButtonVariant.danger),
      ],
    );
  }
}
