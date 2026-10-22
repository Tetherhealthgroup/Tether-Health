// GENERATED from spec/screens/ea_result.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Screener result  ·  route `/p/ea/result`  ·  flow `ea`  ·  kind `screen`
/// Default state · program ea · phase onboarding
/// 
///
/// Actions (generated from spec/screens/ea_result.json):
///   • Back → back
///   • Find a therapist near me → external https://findtreatment.gov
///   • Talk to my primary care doctor → push → support_message_care
///   • Not now → push → ea_plan
///   • Call or text 988 → push → crisis
///   • Call 911 → call 911
/// API: —
class EaResultScreen extends StatelessWidget {
  const EaResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.eaResultHeaderTitle, pill: s.eaResultHeaderPill),
      children: [
        TTitle(s.eaResultBodyN0Text),
        TCard(variant: TCardVariant.mint, text: s.eaResultBodyN1Text),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.eaResultBodyN2RowsN0Label, sub: s.eaResultBodyN2RowsN0Sub, onTap: () => TNav.external(context, 'https://findtreatment.gov')), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.eaResultBodyN2RowsN1Label, sub: s.eaResultBodyN2RowsN1Sub, onTap: () => TNav.push(context, Routes.supportMessageCare)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.eaResultBodyN2RowsN2Label, sub: s.eaResultBodyN2RowsN2Sub, onTap: () => TNav.push(context, Routes.eaPlan))]),
        TEmergencyCard(text: s.eaResultBodyN3Text, actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: s.eaResultBodyN3ActionsN0Label, onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[3].actions[1]'), label: s.eaResultBodyN3ActionsN1Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
    );
  }
}
