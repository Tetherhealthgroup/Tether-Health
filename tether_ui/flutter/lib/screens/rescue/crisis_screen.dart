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
    return TScreen(
      header: THeader(title: 'You’re not alone', left: THeaderLeft.close),
      children: [
        TBanner(kind: TBannerKind.urgent, text: 'If you might act on thoughts of harming yourself, get help now.'),
        TButton(key: const ValueKey('a:body[1]'), label: 'Call 988', onPressed: () => TNav.call(context, '988', label: '988'), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:body[2]'), label: 'Text 988', onPressed: () => TNav.sms(context, '988'), variant: TButtonVariant.secondary),
        TButton(key: const ValueKey('a:body[3]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary),
        TCard(key: const ValueKey('a:body[4]'), eyebrow: 'Your safety plan', title: 'Things that help: walk the dog, shower, music', text: 'Reach out: Sam · (555) 010-3311', onTap: () => TNav.push(context, Routes.eaPlan)),
        TBody('Shown whenever someone chooses “thoughts of harming myself” or types similar words anywhere. Works offline. 988 is US-only; localize per region.', tone: TTextTone.small),
      ],
    );
  }
}
