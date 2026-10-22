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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.rescueEscalateHeaderTitle, left: THeaderLeft.close),
      children: [
        TTitle(s.rescueEscalateBodyN0Text),
        TBody(s.rescueEscalateBodyN1Text, tone: TTextTone.muted),
        TCard(variant: TCardVariant.dark, eyebrow: s.rescueEscalateBodyN2Eyebrow, title: s.rescueEscalateBodyN2Title, text: s.rescueEscalateBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.rescueEscalateBodyN2CtaN0Label, onPressed: () => TNav.call(context, '1-800-784-8669', label: 'Call 1-800-QUIT-NOW'), variant: TButtonVariant.lime, small: true)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: s.rescueEscalateBodyN3RowsN0Label, sub: s.rescueEscalateBodyN3RowsN0Sub, lead: TLead.avatar('J'), onTap: () => TNav.sheet(context, Routes.supportMessage))]),
        TEmergencyCard(text: s.rescueEscalateBodyN4Text, actions: [TButton(key: const ValueKey('a:body[4].actions[0]'), label: s.rescueEscalateBodyN4ActionsN0Label, onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[4].actions[1]'), label: s.rescueEscalateBodyN4ActionsN1Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.rescueEscalateFooterN0Label, onPressed: () => TNav.sheet(context, Routes.rescueTools), variant: TButtonVariant.secondary),
      ],
    );
  }
}
