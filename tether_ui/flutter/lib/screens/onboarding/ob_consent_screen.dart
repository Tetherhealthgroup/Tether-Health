// GENERATED from spec/screens/ob_consent.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Layered consent  ·  route `/onboarding/consent`  ·  flow `onboarding`  ·  kind `screen`
/// Default state · phase onboarding
/// 
///
/// Actions (generated from spec/screens/ob_consent.json):
///   • Back → back
///   • Read the Privacy Notice → external https://www.tetherhealthgroup.com/privacy/
///   • Agree and continue → POST /v1/enrolments/consents then push → ob_basics
/// API: POST /v1/enrolments/consents
class ObConsentScreen extends StatelessWidget {
  const ObConsentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your privacy', pill: '3 of 5'),
      children: [
        TSteps(n: 3, total: 5),
        TTitle('Your story stays yours.'),
        TBody('Each program keeps its own data. Optional choices start off.', tone: TTextTone.muted),
        TCard(eyebrow: 'Account · required', children: [TToggleRow(fieldKey: 'ob_consent.essential_app_data', label: 'Essential app data', sub: 'Account, plans and progress, encrypted. Required.', value: true)]),
        TCard(tag: 'bf', accent: 'bf', children: [TToggleRow(fieldKey: 'ob_consent.private_reminders', label: 'Private reminders', sub: 'Lock screen: “You have a Tether reminder.”'), TToggleRow(fieldKey: 'ob_consent.share_summaries_with_my_care_tea', label: 'Share summaries with my care team', sub: 'You preview every share')]),
        TCard(tag: 'sf', accent: 'sf', children: [TToggleRow(fieldKey: 'ob_consent.connect_screen_time', label: 'Connect Screen Time', sub: 'Optional · totals only, never content'), TToggleRow(fieldKey: 'ob_consent.de_identified_research', label: 'De-identified research')]),
        TBody('No ads. No tobacco-industry funding. We never sell health information.', tone: TTextTone.small),
        TLink(key: const ValueKey('a:body[7]'), label: 'Read the Privacy Notice', onTap: () => TNav.external(context, 'https://www.tetherhealthgroup.com/privacy/'), alignLeft: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Agree and continue', onPressed: () => TNav.submit(context, 'POST /v1/enrolments/consents', screenId: 'ob_consent', then: () => TNav.push(context, Routes.obBasics)), arrow: true),
      ],
    );
  }
}
