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
    return TScreen(
      header: THeader(title: 'Choose apps', pill: 'Step 2 of 3'),
      children: [
        TTitle('Name your groups'),
        TBody('iPhone doesn’t tell Tether the app names, so give each group a name you’ll recognize. Group names stay on this phone.', tone: TTextTone.muted),
        TListGroup(title: 'Your groups', rows: [TListRow(label: 'Video apps', sub: '3 apps'), TListRow(label: 'Feeds', sub: '2 apps')]),
        TField(fieldKey: 'sf_unplug_apps_chosen.group_name', label: 'New group name', placeholder: 'e.g. Games'),
        TButton(key: const ValueKey('a:body[4]'), label: 'Add another group', onPressed: () => TNav.sheet(context, Routes.sfUnplugPickerIos), variant: TButtonVariant.secondary, small: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Next: limits', onPressed: () => TNav.push(context, Routes.sfUnplugLimits), arrow: true),
      ],
    );
  }
}
