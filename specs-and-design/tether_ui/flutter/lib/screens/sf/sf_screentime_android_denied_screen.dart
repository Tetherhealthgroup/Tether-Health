// GENERATED from spec/screens/sf_screentime_android_denied.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Usage access off (Android)  ·  route `/p/sf/screen-time?state=android-denied`  ·  flow `sf`  ·  kind `screen`
/// State: android · not allowed of sf_screentime · program sf · phase plan
/// Copy needs clinical/legal review.
///
/// Actions (generated from spec/screens/sf_screentime_android_denied.json):
///   • Back → back
///   • Continue with self-report → back
///   • Open settings → os_settings
/// API: —
class SfScreentimeAndroidDeniedScreen extends StatelessWidget {
  const SfScreentimeAndroidDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfScreentimeAndroidDeniedHeaderTitle, pill: s.sfScreentimeAndroidDeniedHeaderPill),
      children: [
        TBanner(kind: TBannerKind.info, text: s.sfScreentimeAndroidDeniedBodyN0Text),
        TTitle(s.sfScreentimeAndroidDeniedBodyN1Text),
        TBody(s.sfScreentimeAndroidDeniedBodyN2Text, tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfScreentimeAndroidDeniedFooterN0Label, onPressed: () => TNav.back(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfScreentimeAndroidDeniedFooterN1Label, onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
