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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.checkinDoneHeaderTitle, left: THeaderLeft.close),
      children: [
        TIllustration(glyph: '✓'),
        TBoundValues(keys: const ['checkin.thanks'], place: TExamplePlace.inline, builder: (context, v) => TTitle(v.text('checkin.thanks', s.checkinDoneBodyN1Text), size: TTitleSize.l, center: true)),
        TBody(s.checkinDoneBodyN2Text, center: true),
        TCard(tag: 'bf', title: s.checkinDoneBodyN3Title, text: s.checkinDoneBodyN3Text, cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: s.checkinDoneBodyN3CtaN0Label, onPressed: () => TNav.push(context, Routes.rescueActive), small: true)),
        TCard(tag: 'sf', title: s.checkinDoneBodyN4Title, text: s.checkinDoneBodyN4Text, cta: TButton(key: const ValueKey('a:body[4].cta[0]'), label: s.checkinDoneBodyN4CtaN0Label, onPressed: () => TNav.push(context, Routes.sfGoal), variant: TButtonVariant.secondary, small: true)),
        TBody(s.checkinDoneBodyN5Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.checkinDoneFooterN0Label, onPressed: () => TNav.reset(context, Routes.today), variant: TButtonVariant.secondary),
      ],
    );
  }
}
