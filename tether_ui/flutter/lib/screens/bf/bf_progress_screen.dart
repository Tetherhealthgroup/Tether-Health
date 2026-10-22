// GENERATED from spec/screens/bf_progress.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// BreatheFree progress  ·  route `/p/bf/progress`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase resources
/// 
///
/// Actions (generated from spec/screens/bf_progress.json):
///   • Back → back
///   • How estimates work → sheet → bf_estimates
/// API: —
class BfProgressScreen extends StatelessWidget {
  const BfProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfProgressHeaderTitle, pill: 'BreatheFree'),
      children: [
        TSegmented(fieldKey: 'bf_progress.value', options: ['7 days', '30 days', 'All'], labels: [s.bfProgressBodyN0OptionsN0, s.bfProgressBodyN0OptionsN1, s.bfProgressBodyN0OptionsN2], selected: '7 days'),
        TBarChart(values: [10.0, 7.0, 4.0, 3.0, 1.0, 1.0, 0.0], color: TColors.program('bf'), missing: [3], labels: [s.bfProgressBodyN1LabelsN0, s.bfProgressBodyN1LabelsN1, s.bfProgressBodyN1LabelsN2, s.bfProgressBodyN1LabelsN3, s.bfProgressBodyN1LabelsN4, s.bfProgressBodyN1LabelsN5, s.bfProgressBodyN1LabelsN6], title: s.bfProgressBodyN1Title, caption: s.bfProgressBodyN1Caption),
        TStatGrid(stats: [TStat(label: s.bfProgressBodyN2ItemsN0Label, value: '61', sub: s.bfProgressBodyN2ItemsN0Sub), TStat(label: s.bfProgressBodyN2ItemsN1Label, value: '\$42.70', sub: s.bfProgressBodyN2ItemsN1Sub), TStat(label: s.bfProgressBodyN2ItemsN2Label, value: s.bfProgressBodyN2ItemsN2Value, sub: s.bfProgressBodyN2ItemsN2Sub), TStat(label: s.bfProgressBodyN2ItemsN3Label, value: s.bfProgressBodyN2ItemsN3Value, sub: s.bfProgressBodyN2ItemsN3Sub)]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: s.bfProgressBodyN3RowsN0Label, sub: s.bfProgressBodyN3RowsN0Sub, onTap: () => TNav.sheet(context, Routes.bfEstimates))]),
      ],
    );
  }
}
