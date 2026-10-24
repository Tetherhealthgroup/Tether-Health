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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugAppsHeaderTitle, pill: s.sfUnplugAppsHeaderPill),
      children: [
        TTitle(s.sfUnplugAppsBodyN0Text),
        TBody(s.sfUnplugAppsBodyN1Text, tone: TTextTone.muted),
        TCard(variant: TCardVariant.mint, title: s.sfUnplugAppsBodyN2Title, text: s.sfUnplugAppsBodyN2Text),
        TBody(s.sfUnplugAppsBodyN3Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugAppsFooterN0Label, onPressed: () => TNav.sheet(context, Routes.sfUnplugPickerIos), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugAppsFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
