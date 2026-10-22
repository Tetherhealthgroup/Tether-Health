// GENERATED from spec/screens/records_item.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Imported values  ·  route `/records/item`  ·  flow `records`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/records_item.json):
///   • Back → back
///   • Open in Heartwise → push → hw_trends
/// API: —
class RecordsItemScreen extends StatelessWidget {
  const RecordsItemScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.recordsItemHeaderTitle, pill: '12 + 36'),
      children: [
        TLineChart(values: [142.0, 140.0, 138.0, 139.0, 135.0, 133.0, 136.0, 131.0, 129.0, 130.0, 128.0, 127.0], color: TColors.program('hw'), title: s.recordsItemBodyN0Title, unit: 'mmHg'),
        TListGroup(title: s.recordsItemBodyN1Title, rows: [TListRow(label: s.recordsItemBodyN1RowsN0Label, sub: s.recordsItemBodyN1RowsN0Sub), TListRow(label: s.recordsItemBodyN1RowsN1Label, sub: s.recordsItemBodyN1RowsN1Sub), TListRow(label: s.recordsItemBodyN1RowsN2Label, sub: s.recordsItemBodyN1RowsN2Sub)]),
        TKeyValue(rows: [(s.recordsItemBodyN2RowsN0N0, s.recordsItemBodyN2RowsN0N1), (s.recordsItemBodyN2RowsN1N0, 'Heartwise')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.recordsItemFooterN0Label, onPressed: () => TNav.push(context, Routes.hwTrends), variant: TButtonVariant.secondary),
      ],
    );
  }
}
