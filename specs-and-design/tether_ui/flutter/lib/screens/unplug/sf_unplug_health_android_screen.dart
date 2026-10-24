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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugHealthAndroidHeaderTitle),
      children: [
        TBanner(kind: TBannerKind.success, text: s.sfUnplugHealthAndroidBodyN0Text),
        TChecklist(items: [TCheckItem(s.sfUnplugHealthAndroidBodyN1ItemsN0Label, value: 'Usage access', sub: s.sfUnplugHealthAndroidBodyN1ItemsN0Sub, done: true), TCheckItem(s.sfUnplugHealthAndroidBodyN1ItemsN1Label, value: 'Display over other apps', sub: s.sfUnplugHealthAndroidBodyN1ItemsN1Sub, done: true), TCheckItem(s.sfUnplugHealthAndroidBodyN1ItemsN2Label, value: 'Unplug running in the background', sub: s.sfUnplugHealthAndroidBodyN1ItemsN2Sub, done: true), TCheckItem(s.sfUnplugHealthAndroidBodyN1ItemsN3Label, value: 'Notifications', sub: s.sfUnplugHealthAndroidBodyN1ItemsN3Sub, done: true)], label: s.sfUnplugHealthAndroidBodyN1Label),
        TBody(s.sfUnplugHealthAndroidBodyN2Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugHealthAndroidFooterN0Label, onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugHealthAndroidFooterN1Label, onPressed: () => TNav.back(context), arrow: true),
      ],
    );
  }
}
