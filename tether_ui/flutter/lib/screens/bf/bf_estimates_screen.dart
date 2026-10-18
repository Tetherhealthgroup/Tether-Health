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
    return TSheet(
      children: [
        TTitle('How estimates are calculated'),
        TKeyValue(rows: [('Baseline', '10 cigarettes a day'), ('Price', '\$14.00 per pack'), ('Time per cigarette', '5 minutes'), ('Avoided', 'baseline − reported')]),
        TBody('Estimates, not measurements. Missing days are left out.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Edit numbers', onPressed: () => TNav.toast(context, 'Opened baseline settings', then: () => TNav.close(context)), variant: TButtonVariant.secondary),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Done', onPressed: () => TNav.close(context), arrow: true),
      ],
    );
  }
}
