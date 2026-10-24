// GENERATED from spec/screens/rescue_tools.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Switch tool  ·  route `/rescue/tools`  ·  flow `rescue`  ·  kind `sheet`
/// Default state · phase rescue
/// 
///
/// Actions (generated from spec/screens/rescue_tools.json):
///   • Start this tool → replace → rescue_active
///   • Cancel → close
/// API: —
class RescueToolsScreen extends StatelessWidget {
  const RescueToolsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TTitle(s.rescueToolsBodyN0Text),
        TRadioList(fieldKey: 'rescue_tools.value', items: [TRadioItem(s.rescueToolsBodyN1ItemsN0Label, value: 'Slow breathing', sub: s.rescueToolsBodyN1ItemsN0Sub, badge: s.rescueToolsBodyN1ItemsN0Badge), TRadioItem(s.rescueToolsBodyN1ItemsN1Label, value: 'Move for 3 minutes', sub: s.rescueToolsBodyN1ItemsN1Sub), TRadioItem(s.rescueToolsBodyN1ItemsN2Label, value: 'Change the scene', sub: s.rescueToolsBodyN1ItemsN2Sub), TRadioItem(s.rescueToolsBodyN1ItemsN3Label, value: 'Urge surfing', sub: s.rescueToolsBodyN1ItemsN3Sub)], selected: 1),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.rescueToolsFooterN0Label, onPressed: () => TNav.replace(context, Routes.rescueActive), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.rescueToolsFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
