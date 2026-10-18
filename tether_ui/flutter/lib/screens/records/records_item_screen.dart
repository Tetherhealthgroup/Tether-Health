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
    return TScreen(
      header: THeader(title: 'Blood pressure', pill: '12 + 36'),
      children: [
        TLineChart(values: [142.0, 140.0, 138.0, 139.0, 135.0, 133.0, 136.0, 131.0, 129.0, 130.0, 128.0, 127.0], color: TColors.program('hw'), title: 'Systolic · all sources', unit: 'mmHg'),
        TListGroup(title: 'Latest', rows: [TListRow(label: '128/82 · Oct 15', sub: 'Patel Family Medicine (Epic) · clinic reading'), TListRow(label: '135/85 · Oct 14', sub: 'Entered by you · home monitor'), TListRow(label: '131/80 · Oct 2', sub: 'Patel Family Medicine (Epic)')]),
        TKeyValue(rows: [('Coded as', 'LOINC 85354-9 (8480-6 / 8462-4)'), ('Used by', 'Heartwise')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Open in Heartwise', onPressed: () => TNav.push(context, Routes.hwTrends), variant: TButtonVariant.secondary),
      ],
    );
  }
}
