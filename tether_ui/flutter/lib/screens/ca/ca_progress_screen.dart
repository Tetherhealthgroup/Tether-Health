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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.caProgressHeaderTitle, pill: 'ClearAir'),
      children: [
        TBoundValues(keys: const ['ca.peak_flow_series'], builder: (context, v) => TLineChart(values: v.series('ca.peak_flow_series', const [410.0, 405.0, 398.0, 380.0, 360.0, 310.0, 330.0, 350.0, 372.0, 390.0, 401.0, 404.0]), color: TColors.program('ca'), band: [400.0, 450.0], title: s.caProgressBodyN0Title, unit: 'L/min', caption: s.caProgressBodyN0Caption)),
        TBoundValues(keys: const ['ca.days_green', 'ca.days_yellow', 'ca.days_red'], builder: (context, v) => TStatGrid(columns: 3, stats: [TStat(label: s.caProgressBodyN1ItemsN0Label, value: v.text('ca.days_green', '10')), TStat(label: s.caProgressBodyN1ItemsN1Label, value: v.text('ca.days_yellow', '2')), TStat(label: s.caProgressBodyN1ItemsN2Label, value: v.text('ca.days_red', '0'))])),
        TBoundValues(keys: const ['ca.top_symptom'], builder: (context, v) => TCard(eyebrow: s.caProgressBodyN2Eyebrow, title: v.text('ca.top_symptom', s.caProgressBodyN2Title), text: s.caProgressBodyN2Text)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.caProgressFooterN0Label, onPressed: () => TNav.push(context, Routes.hwSummary), variant: TButtonVariant.secondary),
      ],
    );
  }
}
