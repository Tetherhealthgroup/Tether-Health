// GENERATED from spec/screens/sf_unplug_picker_ios.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Apple app picker  ·  route `/p/sf/unplug/apps/picker`  ·  flow `unplug`  ·  kind `sheet`
/// Default state · program sf · phase plan
/// Copy needs clinical/legal review. Placeholder for the system picker. In the app this sheet is Apple’s; the buttons stand for the picker’s own Done / Cancel.
///
/// Actions (generated from spec/screens/sf_unplug_picker_ios.json):
///   • Done → branch: System app picker result → Apps chosen: replace → sf_unplug_apps_chosen | Cancelled: close
///   • Cancel → close
/// API: —
class SfUnplugPickerIosScreen extends StatelessWidget {
  const SfUnplugPickerIosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      children: [
        TNativeSlot(id: 'ios.familyActivityPicker', label: 'Apple’s app picker', caption: 'System sheet drawn by iOS (FamilyActivityPicker). Tether can’t style it or read the app names.', height: 320.0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Done', onPressed: () => TNav.branch(context, 'System app picker result', <String, VoidCallback>{'Apps chosen': () => TNav.replace(context, Routes.sfUnplugAppsChosen), 'Cancelled': () => TNav.close(context)}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
