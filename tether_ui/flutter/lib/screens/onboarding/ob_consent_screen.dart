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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.obConsentHeaderTitle, pill: s.obConsentHeaderPill),
      children: [
        TSteps(n: 3, total: 5),
        TTitle(s.obConsentBodyN1Text),
        TBody(s.obConsentBodyN2Text, tone: TTextTone.muted),
        TCard(eyebrow: s.obConsentBodyN3Eyebrow, children: [TToggleRow(fieldKey: 'ob_consent.essential_app_data', label: s.obConsentBodyN3ChildrenN0Label, sub: s.obConsentBodyN3ChildrenN0Sub, value: true)]),
        TCard(tag: 'bf', accent: 'bf', children: [TToggleRow(fieldKey: 'ob_consent.private_reminders', label: s.obConsentBodyN4ChildrenN0Label, sub: s.obConsentBodyN4ChildrenN0Sub), TToggleRow(fieldKey: 'ob_consent.share_summaries_with_my_care_tea', label: s.obConsentBodyN4ChildrenN1Label, sub: s.obConsentBodyN4ChildrenN1Sub)]),
        TCard(tag: 'sf', accent: 'sf', children: [TToggleRow(fieldKey: 'ob_consent.connect_screen_time', label: s.obConsentBodyN5ChildrenN0Label, sub: s.obConsentBodyN5ChildrenN0Sub), TToggleRow(fieldKey: 'ob_consent.de_identified_research', label: s.obConsentBodyN5ChildrenN1Label)]),
        TBody(s.obConsentBodyN6Text, tone: TTextTone.small),
        TLink(key: const ValueKey('a:body[7]'), label: s.obConsentBodyN7Label, onTap: () => TNav.external(context, 'https://www.tetherhealthgroup.com/privacy/'), alignLeft: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.obConsentFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/enrolments/consents', screenId: 'ob_consent', then: () => TNav.push(context, Routes.obBasics)), arrow: true),
      ],
    );
  }
}
