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
    return TScreen(
      header: THeader(title: 'Choose apps', pill: 'Step 2 of 3'),
      children: [
        TTitle('Choose the apps to pause'),
        TBody('This choice stays on this phone. Tether never receives it.', tone: TTextTone.muted),
        TChecklist(items: [TCheckItem('Short-video app', done: true), TCheckItem('Photo feed app', done: true), TCheckItem('Video app', done: true), TCheckItem('News app'), TCheckItem('Games app'), TCheckItem('Shopping app')], label: 'Apps on this phone'),
        TBody('Tether, the Phone app and emergency calling aren’t in this list. They can never be paused.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Done · 3 apps', onPressed: () => TNav.replace(context, Routes.sfUnplugAppsChosen), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Cancel', onTap: () => TNav.back(context)),
      ],
    );
  }
}
