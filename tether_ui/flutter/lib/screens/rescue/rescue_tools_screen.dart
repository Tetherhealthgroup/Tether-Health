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
    return TSheet(
      children: [
        TTitle('Choose another tool'),
        TRadioList(fieldKey: 'rescue_tools.value', items: [TRadioItem('Slow breathing', sub: '2 min · voice optional', badge: 'Helped before'), TRadioItem('Move for 3 minutes', sub: 'Walk or stretch'), TRadioItem('Change the scene', sub: 'Go somewhere smoke-free'), TRadioItem('Urge surfing', sub: '3 min audio')], selected: 1),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Start this tool', onPressed: () => TNav.replace(context, Routes.rescueActive), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
