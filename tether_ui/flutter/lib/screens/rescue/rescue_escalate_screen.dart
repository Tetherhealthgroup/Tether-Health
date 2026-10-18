// GENERATED from spec/screens/rescue_escalate.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Add a person  ·  route `/rescue/escalate`  ·  flow `rescue`  ·  kind `screen`
/// Default state · phase rescue
/// 
///
/// Actions (generated from spec/screens/rescue_escalate.json):
///   • Close → close
///   • Call → call 1-800-784-8669
///   • Text Jordan → sheet → support_message
///   • Call or text 988 → push → crisis
///   • Call 911 → call 911
///   • Try another tool → sheet → rescue_tools
/// API: —
class RescueEscalateScreen extends StatelessWidget {
  const RescueEscalateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Rescue', left: THeaderLeft.close),
      children: [
        TTitle('Let’s add a person.'),
        TBody('Strong cravings are common in the first days. You don’t have to ride this one alone.', tone: TTextTone.muted),
        TCard(variant: TCardVariant.dark, eyebrow: 'Free & confidential', title: 'Quitline counselor', text: '1-800-QUIT-NOW · many states 24/7', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Call', onPressed: () => TNav.call(context, '1-800-784-8669', label: 'Call 1-800-QUIT-NOW'), variant: TButtonVariant.lime, small: true)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Text Jordan', sub: '“Can you stay with me for 10 minutes?”', lead: TLead.avatar('J'), onTap: () => TNav.sheet(context, Routes.supportMessage))]),
        TEmergencyCard(text: 'Thoughts of harming yourself? Call or text 988. Emergency: 911.', actions: [TButton(key: const ValueKey('a:body[4].actions[0]'), label: 'Call or text 988', onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[4].actions[1]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Try another tool', onPressed: () => TNav.sheet(context, Routes.rescueTools), variant: TButtonVariant.secondary),
      ],
    );
  }
}
