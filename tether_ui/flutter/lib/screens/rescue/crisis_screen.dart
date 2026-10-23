// GENERATED from spec/screens/crisis.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Crisis support  ·  route `/crisis`  ·  flow `rescue`  ·  kind `fullscreen`
/// Default state · phase rescue
/// Global crisis screen used by every program.
///
/// Actions (generated from spec/screens/crisis.json):
///   • Close → close
///   • Call 988 → call 988
///   • Text 988 → sms 988
///   • Call 911 → call 911
///   • Things that help: walk the dog, shower, music → push → ea_plan
/// API: —
class CrisisScreen extends StatelessWidget {
  const CrisisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.crisisHeaderTitle, left: THeaderLeft.close),
      children: [
        TBanner(kind: TBannerKind.urgent, text: s.crisisBodyN0Text),
        TButton(key: const ValueKey('a:body[1]'), label: s.crisisBodyN1Label, onPressed: () => TNav.call(context, '988', label: '988'), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:body[2]'), label: s.crisisBodyN2Label, onPressed: () => TNav.sms(context, '988'), variant: TButtonVariant.secondary),
        TButton(key: const ValueKey('a:body[3]'), label: s.crisisBodyN3Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary),
        TBoundValues(keys: const ['ea.plan.things_that_help_line', 'ea.plan.reach_out_line'], builder: (context, v) => TCard(key: const ValueKey('a:body[4]'), eyebrow: s.crisisBodyN4Eyebrow, title: v.text('ea.plan.things_that_help_line', s.crisisBodyN4Title), text: v.text('ea.plan.reach_out_line', s.crisisBodyN4Text), onTap: () => TNav.push(context, Routes.eaPlan))),
      ],
    );
  }
}
