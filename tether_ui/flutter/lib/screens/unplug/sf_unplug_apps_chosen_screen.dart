// GENERATED from spec/screens/sf_unplug_apps_chosen.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Name your groups  ·  route `/p/sf/unplug/apps?state=chosen`  ·  flow `unplug`  ·  kind `screen`
/// State: apps chosen of sf_unplug_apps · program sf · phase plan
/// Copy needs clinical/legal review. PlatformAppSelection carries only the person’s group labels and counts. Group names are device-only (not synced).
///
/// Actions (generated from spec/screens/sf_unplug_apps_chosen.json):
///   • Back → back
///   • Add another group → sheet → sf_unplug_picker_ios
///   • Next: limits → push → sf_unplug_limits
/// API: —
class SfUnplugAppsChosenScreen extends StatelessWidget {
  const SfUnplugAppsChosenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugAppsChosenHeaderTitle, pill: s.sfUnplugAppsChosenHeaderPill),
      children: [
        TTitle(s.sfUnplugAppsChosenBodyN0Text),
        TBody(s.sfUnplugAppsChosenBodyN1Text, tone: TTextTone.muted),
        TBoundValues(keys: const ['sf.unplug.group_1_name', 'sf.unplug.group_1_apps', 'sf.unplug.group_2_name', 'sf.unplug.group_2_apps'], builder: (context, v) => TListGroup(title: s.sfUnplugAppsChosenBodyN2Title, rows: [TListRow(label: v.text('sf.unplug.group_1_name', s.sfUnplugAppsChosenBodyN2RowsN0Label), sub: v.text('sf.unplug.group_1_apps', s.sfUnplugAppsChosenBodyN2RowsN0Sub)), TListRow(label: v.text('sf.unplug.group_2_name', s.sfUnplugAppsChosenBodyN2RowsN1Label), sub: v.text('sf.unplug.group_2_apps', s.sfUnplugAppsChosenBodyN2RowsN1Sub))])),
        TField(fieldKey: 'sf_unplug_apps_chosen.group_name', label: s.sfUnplugAppsChosenBodyN3Label, placeholder: s.sfUnplugAppsChosenBodyN3Placeholder),
        TButton(key: const ValueKey('a:body[4]'), label: s.sfUnplugAppsChosenBodyN4Label, onPressed: () => TNav.sheet(context, Routes.sfUnplugPickerIos), variant: TButtonVariant.secondary, small: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugAppsChosenFooterN0Label, onPressed: () => TNav.push(context, Routes.sfUnplugLimits), arrow: true),
      ],
    );
  }
}
