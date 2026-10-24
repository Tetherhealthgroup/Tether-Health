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
///   • Disconnect → sheet → records_disconnect
/// API: —
class RecordsSourceScreen extends StatelessWidget {
  const RecordsSourceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsSourceHeaderTitle),
      children: [
        TBoundValues(keys: const ['records.source.connection', 'records.source.last_sync', 'records.source.next_sync', 'records.source.access', 'records.source.connected_on'], builder: (context, v) => TKeyValue(rows: [(s.recordsSourceBodyN0RowsN0N0, v.text('records.source.connection', s.recordsSourceBodyN0RowsN0N1)), (s.recordsSourceBodyN0RowsN1N0, v.text('records.source.last_sync', s.recordsSourceBodyN0RowsN1N1)), (s.recordsSourceBodyN0RowsN2N0, v.text('records.source.next_sync', s.recordsSourceBodyN0RowsN2N1)), (s.recordsSourceBodyN0RowsN3N0, v.text('records.source.access', s.recordsSourceBodyN0RowsN3N1)), (s.recordsSourceBodyN0RowsN4N0, v.text('records.source.connected_on', s.recordsSourceBodyN0RowsN4N1))])),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: s.recordsSourceBodyN1RowsN0Label, onTap: () => TNav.submit(context, 'POST /v1/records/fhir/sources/:id/sync', screenId: 'records_source', then: () => TNav.toast(context, s.recordsSourceBodyN1RowsN0ActionThenValue)))]),
        TListGroup(title: s.recordsSourceBodyN2Title, rows: [TListRow(label: s.recordsSourceBodyN2RowsN0Label, sub: s.recordsSourceBodyN2RowsN0Sub), TListRow(label: s.recordsSourceBodyN2RowsN1Label, sub: s.recordsSourceBodyN2RowsN1Sub), TListRow(label: s.recordsSourceBodyN2RowsN2Label, sub: s.recordsSourceBodyN2RowsN2Sub), TListRow(label: s.recordsSourceBodyN2RowsN3Label, sub: s.recordsSourceBodyN2RowsN3Sub), TListRow(label: s.recordsSourceBodyN2RowsN4Label, sub: s.recordsSourceBodyN2RowsN4Sub), TListRow(label: s.recordsSourceBodyN2RowsN5Label, sub: s.recordsSourceBodyN2RowsN5Sub)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsSourceFooterN0Label, onPressed: () => TNav.sheet(context, Routes.recordsDisconnect, argument: TNav.argumentOf(context)), variant: TButtonVariant.danger),
      ],
    );
  }
}
