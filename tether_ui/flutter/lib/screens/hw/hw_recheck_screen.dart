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
    return TScreen(
      header: THeader(title: 'Re-check', left: THeaderLeft.close),
      children: [
        TTitle('Rest, then measure again.', center: true),
        TTimer(value: '4:12', label: 'until re-check'),
        TCard(children: [TChecklist(items: [TCheckItem('Sit with your back supported'), TCheckItem('Feet flat, arm at heart level'), TCheckItem('No talking while measuring')])]),
        TEmergencyCard(text: 'New chest pain, weakness or trouble speaking? Call 911 now.', actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger, small: true)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Re-check now', onPressed: () => TNav.replace(context, Routes.hwLog), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Contact my clinician', onPressed: () => TNav.push(context, Routes.supportMessageCare), variant: TButtonVariant.secondary),
      ],
    );
  }
}
