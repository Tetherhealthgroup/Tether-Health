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
    return TScreen(
      header: THeader(title: 'Progress', pill: 'BreatheFree'),
      children: [
        TSegmented(fieldKey: 'bf_progress.value', options: ['7 days', '30 days', 'All'], selected: '7 days'),
        TBarChart(values: [10.0, 7.0, 4.0, 3.0, 1.0, 1.0, 0.0], color: TColors.program('bf'), missing: [3], labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'], title: 'Cigarettes / day', caption: 'Thursday: no check-in · not counted as zero'),
        TStatGrid(stats: [TStat(label: 'Est. avoided', value: '61', sub: 'cigarettes'), TStat(label: 'Est. saved', value: '\$42.70', sub: '\$14 per pack'), TStat(label: 'Cravings eased', value: '4 of 6', sub: 'after a tool'), TStat(label: 'Most helpful', value: 'Breathing', sub: '3 of 4 times')]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'How estimates work', sub: '10/day · \$14/pack · 5 min each', onTap: () => TNav.sheet(context, Routes.bfEstimates))]),
      ],
    );
  }
}
