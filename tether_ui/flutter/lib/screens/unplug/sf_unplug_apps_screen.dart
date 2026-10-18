// GENERATED from spec/screens/sf_unplug_apps.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Choose apps  ·  route `/p/sf/unplug/apps`  ·  flow `unplug`  ·  kind `screen`
/// Default state · program sf · phase plan
/// Copy needs clinical/legal review. iPhone host screen around Apple’s FamilyActivityPicker. presentAppPicker returns only a count; app identities stay as device-local tokens.
///
/// Actions (generated from spec/screens/sf_unplug_apps.json):
///   • Back → back
///   • Open app picker → sheet → sf_unplug_picker_ios
///   • Not now → back
/// API: —
class SfUnplugAppsScreen extends StatelessWidget {
  const SfUnplugAppsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Choose apps', pill: 'Step 2 of 3'),
      children: [
        TTitle('Which apps should Unplug pause?'),
        TBody('Apple’s app picker opens next. Tether never sees which apps you pick: Apple keeps that choice on this phone.', tone: TTextTone.muted),
        TCard(variant: TCardVariant.mint, title: 'Start small', text: 'One or two apps that pull you in most is a good start. You can change this anytime.'),
        TBody('Tether, the phone dialer and emergency calling can never be chosen or paused.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Open app picker', onPressed: () => TNav.sheet(context, Routes.sfUnplugPickerIos), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Not now', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
