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
    return TScreen(
      header: THeader(title: 'Screen Time', pill: 'Optional'),
      children: [
        TBanner(kind: TBannerKind.info, text: 'Usage access is still off.'),
        TTitle('Self-report works just as well.'),
        TBody('We’ll ask for a quick estimate in your evening check-in. You can connect later in Account → ScrollFree.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue with self-report', onPressed: () => TNav.back(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Open settings', onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
