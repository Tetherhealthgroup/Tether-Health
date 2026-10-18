// GENERATED from spec/screens/nu_protect.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Protective mode  ·  route `/p/nu/support`  ·  flow `nu`  ·  kind `screen`
/// Default state · program nu · phase rescue
/// 
///
/// Actions (generated from spec/screens/nu_protect.json):
///   • Back → back
///   • Prepare → push → support_message_care
///   • Call or text 988 → push → crisis
///   • Call 911 → call 911
///   • Continue with gentle habits → replace → nu_habit (onboarding: nu_habit)
/// API: —
class NuProtectScreen extends StatelessWidget {
  const NuProtectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Support', pill: 'Private'),
      children: [
        TTitle('Thanks for telling us.'),
        TBody('Nourish has turned off weight, amount goals and before/after comparisons.', tone: TTextTone.muted),
        TCard(title: 'Talking to someone can help', text: 'A clinician or eating-disorder specialist can support you. We can help you prepare what to say.', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Prepare', onPressed: () => TNav.push(context, Routes.supportMessageCare), small: true)),
        TEmergencyCard(text: 'In crisis? Call or text 988 · Emergency 911', actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: 'Call or text 988', onPressed: () => TNav.push(context, Routes.crisis), variant: TButtonVariant.danger, small: true), TButton(key: const ValueKey('a:body[3].actions[1]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.secondary, small: true)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue with gentle habits', onPressed: () => TNav.replace(context, (TFlow.onboarding ? Routes.nuHabit : Routes.nuHabit)), arrow: true),
      ],
    );
  }
}
