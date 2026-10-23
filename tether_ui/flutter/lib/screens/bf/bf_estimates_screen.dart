// GENERATED from spec/screens/bf_estimates.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// How estimates work  ·  route `/p/bf/progress/estimates`  ·  flow `bf`  ·  kind `sheet`
/// Default state · program bf · phase resources
/// 
///
/// Actions (generated from spec/screens/bf_estimates.json):
///   • Edit numbers → toast “Opened baseline settings” then close
///   • Done → close
/// API: —
class BfEstimatesScreen extends StatelessWidget {
  const BfEstimatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TTitle(s.bfEstimatesBodyN0Text),
        TBoundValues(keys: const ['bf.estimates.baseline', 'bf.estimates.price', 'bf.estimates.time_per_cigarette'], builder: (context, v) => TKeyValue(rows: [(s.bfEstimatesBodyN1RowsN0N0, v.text('bf.estimates.baseline', s.bfEstimatesBodyN1RowsN0N1)), (s.bfEstimatesBodyN1RowsN1N0, v.text('bf.estimates.price', s.bfEstimatesBodyN1RowsN1N1)), (s.bfEstimatesBodyN1RowsN2N0, v.text('bf.estimates.time_per_cigarette', s.bfEstimatesBodyN1RowsN2N1)), (s.bfEstimatesBodyN1RowsN3N0, s.bfEstimatesBodyN1RowsN3N1)])),
        TBody(s.bfEstimatesBodyN2Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfEstimatesFooterN0Label, onPressed: () => TNav.toast(context, s.bfEstimatesFooterN0ActionValue, then: () => TNav.close(context)), variant: TButtonVariant.secondary),
        TButton(key: const ValueKey('a:footer[1]'), label: s.bfEstimatesFooterN1Label, onPressed: () => TNav.close(context), arrow: true),
      ],
    );
  }
}
