// GENERATED from spec/screens/hw_crisis.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Crisis range  ·  route `/p/hw/crisis`  ·  flow `hw`  ·  kind `fullscreen`
/// Default state · program hw · phase rescue
/// 
///
/// Actions (generated from spec/screens/hw_crisis.json):
///   • Close → close
///   • Yes · call 911 → call 911
///   • No symptoms · re-check in 5 min → replace → hw_recheck
/// API: —
class HwCrisisScreen extends StatelessWidget {
  const HwCrisisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.hwCrisisHeaderTitle, left: THeaderLeft.close),
      children: [
        TBanner(kind: TBannerKind.urgent, text: s.hwCrisisBodyN0Text),
        TCard(variant: TCardVariant.urgent, title: s.hwCrisisBodyN1Title, text: s.hwCrisisBodyN1Text),
        TButton(key: const ValueKey('a:body[2]'), label: s.hwCrisisBodyN2Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:body[3]'), label: s.hwCrisisBodyN3Label, onPressed: () => TNav.replace(context, Routes.hwRecheck), variant: TButtonVariant.secondary),
        TBody(s.hwCrisisBodyN4Text, tone: TTextTone.small),
      ],
    );
  }
}
