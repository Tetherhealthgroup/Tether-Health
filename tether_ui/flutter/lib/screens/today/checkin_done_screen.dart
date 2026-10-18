// GENERATED from spec/screens/checkin_done.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Check-in saved  ·  route `/check-in/done`  ·  flow `today`  ·  kind `screen`
/// Default state · phase daily
/// 
///
/// Actions (generated from spec/screens/checkin_done.json):
///   • Close → close
///   • Start → push → rescue_active
///   • Set it → push → sf_goal
///   • Back to Today → reset → today
/// API: —
class CheckinDoneScreen extends StatelessWidget {
  const CheckinDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Check-in saved', left: THeaderLeft.close),
      children: [
        TIllustration(glyph: '✓'),
        TTitle('Thanks, Alex.', size: TTitleSize.l, center: true),
        TBody('One small step for each program today.', center: true),
        TCard(tag: 'bf', title: 'Try a 3-minute stress reset', text: 'You reported high stress', cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: 'Start', onPressed: () => TNav.push(context, Routes.rescueActive), small: true)),
        TCard(tag: 'sf', title: 'Set a 10 PM wind-down', text: 'You felt drained after scrolling', cta: TButton(key: const ValueKey('a:body[4].cta[0]'), label: 'Set it', onPressed: () => TNav.push(context, Routes.sfGoal), variant: TButtonVariant.secondary, small: true)),
        TBody('Recommendations use only today’s answers · v1.0', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Back to Today', onPressed: () => TNav.reset(context, Routes.today), variant: TButtonVariant.secondary),
      ],
    );
  }
}
