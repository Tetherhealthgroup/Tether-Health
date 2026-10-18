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
    return TScreen(
      header: THeader(title: 'Screen Time', pill: 'Optional'),
      children: [
        TBanner(kind: TBannerKind.info, text: 'Screen Time access was not allowed.'),
        TTitle('Self-report works just as well.'),
        TBody('We’ll ask for a quick estimate in your evening check-in. You can connect later in Account → ScrollFree.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue with self-report', onPressed: () => TNav.back(context), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Open phone settings', onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
