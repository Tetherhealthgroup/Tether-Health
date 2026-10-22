// GENERATED from spec/screens/account_privacy.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Privacy & consent  ·  route `/account/privacy`  ·  flow `account`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/account_privacy.json):
///   • Back → back
///   • Care-team sharing → push → account_programs
///   • Consent history → toast “Consent history opened”
///   • Privacy Notice → external https://www.tetherhealthgroup.com/privacy/
///   • Save → PATCH /v1/enrolments/consents then toast “Saved” then back
/// API: —
class AccountPrivacyScreen extends StatelessWidget {
  const AccountPrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Privacy & consent'),
      children: [
        TCard(eyebrow: 'Choices', children: [TToggleRow(fieldKey: 'account_privacy.cross_program_insights', label: 'Cross-program insights', sub: 'Show connections between your programs', value: true, bind: 'consents.cross_program_insights'), TToggleRow(fieldKey: 'account_privacy.de_identified_research', label: 'De-identified research', sub: 'Per program, off by default', bind: 'consents.de_identified_research'), TToggleRow(fieldKey: 'account_privacy.anonymous_app_diagnostics', label: 'Anonymous app diagnostics', sub: 'No health entries', bind: 'consents.anonymous_app_diagnostics')]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'Care-team sharing', sub: 'Manual only · preview every share', onTap: () => TNav.push(context, Routes.accountPrograms)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'Consent history', sub: 'v3 · Aug 22, 2026', onTap: () => TNav.toast(context, 'Consent history opened')), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: 'Privacy Notice', onTap: () => TNav.external(context, 'https://www.tetherhealthgroup.com/privacy/'))]),
        TBody('No ads. We never sell your health data.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'PATCH /v1/enrolments/consents', screenId: 'account_privacy', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
