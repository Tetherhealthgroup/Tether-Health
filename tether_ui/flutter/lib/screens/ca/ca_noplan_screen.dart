// GENERATED from spec/screens/ca_noplan.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// No action plan yet  ·  route `/p/ca/plan?state=none`  ·  flow `ca`  ·  kind `screen`
/// State: empty of ca_plan · program ca · phase plan
/// 
///
/// Actions (generated from spec/screens/ca_noplan.json):
///   • Back → back
///   • Symptom diary → push → ca_symptoms
///   • Questions for my next visit → push → learn_lesson
///   • Message my care team → push → support_message_care
///   • Continue to ClearAir → replace → ca_home (onboarding: ob_setup)
/// API: —
class CaNoplanScreen extends StatelessWidget {
  const CaNoplanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'No action plan', pill: 'Learn'),
      children: [
        TIllustration(glyph: 'i', tone: TTone.warn),
        TTitle('Let’s get you a plan first', center: true),
        TBody('Zone checks need a plan from your clinician. Until then you can learn, log symptoms and prepare questions.', tone: TTextTone.muted, center: true),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Symptom diary', sub: 'Shareable with your clinician', onTap: () => TNav.push(context, Routes.caSymptoms)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'Questions for my next visit', onTap: () => TNav.push(context, Routes.learnLesson)), TListRow(key: const ValueKey('a:body[3].rows[2]'), label: 'Message my care team', onTap: () => TNav.push(context, Routes.supportMessageCare))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue to ClearAir', onPressed: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.caHome)), arrow: true),
      ],
    );
  }
}
