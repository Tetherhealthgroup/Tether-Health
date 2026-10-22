// GENERATED from spec/screens/hw_recheck.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Re-check timer  ·  route `/p/hw/crisis/recheck`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase rescue
/// 
///
/// Actions (generated from spec/screens/hw_recheck.json):
///   • Close → close
///   • Call 911 → call 911
///   • Re-check now → replace → hw_log
///   • Contact my clinician → push → support_message_care
/// API: —
class HwRecheckScreen extends StatelessWidget {
  const HwRecheckScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.hwRecheckHeaderTitle, left: THeaderLeft.close),
      children: [
        TTitle(s.hwRecheckBodyN0Text, center: true),
        TTimer(value: '4:12', label: s.hwRecheckBodyN1Label),
        TCard(children: [TChecklist(items: [TCheckItem(s.hwRecheckBodyN2ChildrenN0ItemsN0Label, value: 'Sit with your back supported'), TCheckItem(s.hwRecheckBodyN2ChildrenN0ItemsN1Label, value: 'Feet flat, arm at heart level'), TCheckItem(s.hwRecheckBodyN2ChildrenN0ItemsN2Label, value: 'No talking while measuring')])]),
        TEmergencyCard(text: s.hwRecheckBodyN3Text, actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: s.hwRecheckBodyN3ActionsN0Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger, small: true)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.hwRecheckFooterN0Label, onPressed: () => TNav.replace(context, Routes.hwLog), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.hwRecheckFooterN1Label, onPressed: () => TNav.push(context, Routes.supportMessageCare), variant: TButtonVariant.secondary),
      ],
    );
  }
}
