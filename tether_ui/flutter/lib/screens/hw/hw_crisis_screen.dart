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
    return TScreen(
      header: THeader(title: 'Check this reading', left: THeaderLeft.close),
      children: [
        TBanner(kind: TBannerKind.urgent, text: '186/122 is in a range that needs attention now.'),
        TCard(variant: TCardVariant.urgent, title: 'Do you have any of these right now?', text: 'Chest pain · shortness of breath · back pain · numbness or weakness · vision change · trouble speaking'),
        TButton(key: const ValueKey('a:body[2]'), label: 'Yes · call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:body[3]'), label: 'No symptoms · re-check in 5 min', onPressed: () => TNav.replace(context, Routes.hwRecheck), variant: TButtonVariant.secondary),
        TBody('If it’s still this high on re-check, contact your clinician today. Heartwise doesn’t diagnose.', tone: TTextTone.small),
      ],
    );
  }
}
