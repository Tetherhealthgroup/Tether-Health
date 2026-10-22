// GENERATED from spec/screens/sf_unplug_apps_android.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Choose apps (Android)  ·  route `/p/sf/unplug/apps?state=android`  ·  flow `unplug`  ·  kind `screen`
/// State: android of sf_unplug_apps · program sf · phase plan
/// Copy needs clinical/legal review. Android draws its own picker (AppPickerActivity, native layout must match this screen). App names shown here are generic examples; the real list is the phone’s launchable apps.
///
/// Actions (generated from spec/screens/sf_unplug_apps_android.json):
///   • Back → back
///   • Done · 3 apps → replace → sf_unplug_apps_chosen
///   • Cancel → back
/// API: —
class SfUnplugAppsAndroidScreen extends StatelessWidget {
  const SfUnplugAppsAndroidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugAppsAndroidHeaderTitle, pill: s.sfUnplugAppsAndroidHeaderPill),
      children: [
        TTitle(s.sfUnplugAppsAndroidBodyN0Text),
        TBody(s.sfUnplugAppsAndroidBodyN1Text, tone: TTextTone.muted),
        TChecklist(items: [TCheckItem(s.sfUnplugAppsAndroidBodyN2ItemsN0Label, value: 'Short-video app', done: true), TCheckItem(s.sfUnplugAppsAndroidBodyN2ItemsN1Label, value: 'Photo feed app', done: true), TCheckItem(s.sfUnplugAppsAndroidBodyN2ItemsN2Label, value: 'Video app', done: true), TCheckItem(s.sfUnplugAppsAndroidBodyN2ItemsN3Label, value: 'News app'), TCheckItem(s.sfUnplugAppsAndroidBodyN2ItemsN4Label, value: 'Games app'), TCheckItem(s.sfUnplugAppsAndroidBodyN2ItemsN5Label, value: 'Shopping app')], label: s.sfUnplugAppsAndroidBodyN2Label),
        TBody(s.sfUnplugAppsAndroidBodyN3Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugAppsAndroidFooterN0Label, onPressed: () => TNav.replace(context, Routes.sfUnplugAppsChosen), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.sfUnplugAppsAndroidFooterN1Label, onTap: () => TNav.back(context)),
      ],
    );
  }
}
