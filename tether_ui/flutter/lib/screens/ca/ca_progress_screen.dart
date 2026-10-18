// GENERATED from spec/screens/ca_progress.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// ClearAir progress  ·  route `/p/ca/progress`  ·  flow `ca`  ·  kind `screen`
/// Default state · program ca · phase resources
/// 
///
/// Actions (generated from spec/screens/ca_progress.json):
///   • Back → back
///   • Create visit summary → push → hw_summary
/// API: —
class CaProgressScreen extends StatelessWidget {
  const CaProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Progress', pill: 'ClearAir'),
      children: [
        TLineChart(values: [410.0, 405.0, 398.0, 380.0, 360.0, 310.0, 330.0, 350.0, 372.0, 390.0, 401.0, 404.0], color: TColors.program('ca'), band: [400.0, 450.0], title: 'Peak flow · 12 days', unit: 'L/min', caption: 'Shaded: your green zone, from your plan'),
        TStatGrid(columns: 3, stats: [TStat(label: 'Green', value: '10'), TStat(label: 'Yellow', value: '2'), TStat(label: 'Red', value: '0')]),
        TCard(eyebrow: 'Most common symptom', title: 'Wheezing at night (3×)', text: 'Worth mentioning at your next visit.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Create visit summary', onPressed: () => TNav.push(context, Routes.hwSummary), variant: TButtonVariant.secondary),
      ],
    );
  }
}
