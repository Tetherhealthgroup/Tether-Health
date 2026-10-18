// GENERATED from spec/screens/hw_trends.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Trends  ·  route `/p/hw/trends`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase resources
/// 
///
/// Actions (generated from spec/screens/hw_trends.json):
///   • Back → back
///   • Create visit summary → push → hw_summary
/// API: —
class HwTrendsScreen extends StatelessWidget {
  const HwTrendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Trends', pill: 'Heartwise'),
      children: [
        TSegmented(fieldKey: 'hw_trends.value', options: ['7 days', '30 days', '90 days'], selected: '30 days'),
        TLineChart(values: [142.0, 140.0, 138.0, 139.0, 135.0, 133.0, 136.0, 131.0, 129.0, 130.0, 128.0, 127.0], color: TColors.program('hw'), band: [110.0, 130.0], title: 'Systolic · morning avg', unit: 'target < 130', caption: 'Shaded: your clinician’s target'),
        TStatGrid(stats: [TStat(label: '30-day avg', value: '132/82'), TStat(label: 'Readings', value: '48', sub: '4 days missed')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Create visit summary', onPressed: () => TNav.push(context, Routes.hwSummary), variant: TButtonVariant.secondary),
      ],
    );
  }
}
