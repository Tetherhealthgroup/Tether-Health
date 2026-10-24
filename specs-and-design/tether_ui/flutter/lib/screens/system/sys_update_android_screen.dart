// GENERATED from spec/screens/sys_update_android.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Update required (Android)  ·  route `/system/update?state=android`  ·  flow `system`  ·  kind `fullscreen`
/// State: android of sys_update · phase account
/// Copy needs clinical/legal review. Same as Update required; Update now opens Google Play. The iPhone App Store URL in the base screen still needs the real App Store ID.
///
/// Actions (generated from spec/screens/sys_update_android.json):
///   • Update now → external https://play.google.com/store/apps/details?id=com.TetherHealthLLC.tetherhealth
///   • Open Rescue → sheet → rescue_pick
/// API: —
class SysUpdateAndroidScreen extends StatelessWidget {
  const SysUpdateAndroidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sysUpdateAndroidHeaderTitle, left: THeaderLeft.none),
      children: [
        TIllustration(glyph: '↑', tone: TTone.warn),
        TTitle(s.sysUpdateAndroidBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.sysUpdateAndroidBodyN2Text, tone: TTextTone.muted, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sysUpdateAndroidFooterN0Label, onPressed: () => TNav.external(context, 'https://play.google.com/store/apps/details?id=com.TetherHealthLLC.tetherhealth'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sysUpdateAndroidFooterN1Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue),
      ],
    );
  }
}
