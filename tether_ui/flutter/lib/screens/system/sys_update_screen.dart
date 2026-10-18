// GENERATED from spec/screens/sys_update.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Update required  ·  route `/system/update`  ·  flow `system`  ·  kind `fullscreen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/sys_update.json):
///   • Update now → external https://apps.apple.com/app/tether-health
///   • Open Rescue → sheet → rescue_pick
/// API: —
class SysUpdateScreen extends StatelessWidget {
  const SysUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Update needed', left: THeaderLeft.none),
      children: [
        TIllustration(glyph: '↑', tone: TTone.warn),
        TTitle('A safety update is ready', size: TTitleSize.l, center: true),
        TBody('This version has important fixes. Rescue and Support still work until you update.', tone: TTextTone.muted, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Update now', onPressed: () => TNav.external(context, 'https://apps.apple.com/app/tether-health'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Open Rescue', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue),
      ],
    );
  }
}
