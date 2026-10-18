// GENERATED from spec/screens/hw_result.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Reading saved  ·  route `/p/hw/log/result`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase daily
/// 
///
/// Actions (generated from spec/screens/hw_result.json):
///   • Close → close
///   • See trends → replace → hw_trends
///   • Back to Heartwise → replace → hw_home
/// API: —
class HwResultScreen extends StatelessWidget {
  const HwResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Saved', left: THeaderLeft.close),
      children: [
        TIllustration(glyph: '✓'),
        TTitle('135/85 saved', size: TTitleSize.l, center: true),
        TBody('Average of 2 readings. Your clinician’s target is below 130/80.', tone: TTextTone.muted, center: true),
        TCard(variant: TCardVariant.mint, text: 'One reading is information, not a grade. Trends over weeks matter most.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'See trends', onPressed: () => TNav.replace(context, Routes.hwTrends), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Back to Heartwise', onPressed: () => TNav.replace(context, Routes.hwHome), variant: TButtonVariant.secondary),
      ],
    );
  }
}
