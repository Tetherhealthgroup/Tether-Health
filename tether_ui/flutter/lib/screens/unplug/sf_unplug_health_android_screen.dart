// GENERATED from spec/screens/sf_unplug_health_android.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Tracking check (Android)  ·  route `/p/sf/unplug/health?state=android`  ·  flow `unplug`  ·  kind `screen`
/// State: android of sf_unplug_health · program sf · phase daily
/// Copy needs clinical/legal review.
///
/// Actions (generated from spec/screens/sf_unplug_health_android.json):
///   • Back → back
///   • Battery settings → os_settings
///   • Done → back
/// API: —
class SfUnplugHealthAndroidScreen extends StatelessWidget {
  const SfUnplugHealthAndroidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Tracking check'),
      children: [
        TBanner(kind: TBannerKind.success, text: 'Unplug is working. All 4 checks pass.'),
        TChecklist(items: [TCheckItem('Usage access', sub: 'On', done: true), TCheckItem('Display over other apps', sub: 'On', done: true), TCheckItem('Unplug running in the background', sub: 'Checked 12 s ago', done: true), TCheckItem('Notifications', sub: 'On · needed for the “Tether is running” notice', done: true)], label: 'Android checks'),
        TBody('Some phones stop background apps to save battery. If Unplug keeps stopping, let Tether run in the background.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Battery settings', onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Done', onPressed: () => TNav.back(context), arrow: true),
      ],
    );
  }
}
