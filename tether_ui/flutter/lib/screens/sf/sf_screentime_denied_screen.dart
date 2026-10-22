// GENERATED from spec/screens/sf_screentime_denied.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Screen Time denied  ·  route `/p/sf/screen-time?state=denied`  ·  flow `sf`  ·  kind `screen`
/// State: permission denied of sf_screentime · program sf · phase plan
/// 
///
/// Actions (generated from spec/screens/sf_screentime_denied.json):
///   • Back → back
///   • Continue with self-report → back
///   • Open phone settings → os_settings
/// API: —
class SfScreentimeDeniedScreen extends StatelessWidget {
  const SfScreentimeDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfScreentimeDeniedHeaderTitle, pill: s.sfScreentimeDeniedHeaderPill),
      children: [
        TBanner(kind: TBannerKind.info, text: s.sfScreentimeDeniedBodyN0Text),
        TTitle(s.sfScreentimeDeniedBodyN1Text),
        TBody(s.sfScreentimeDeniedBodyN2Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfScreentimeDeniedFooterN0Label, onPressed: () => TNav.back(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfScreentimeDeniedFooterN1Label, onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
