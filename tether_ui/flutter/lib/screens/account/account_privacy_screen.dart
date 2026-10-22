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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.accountPrivacyHeaderTitle),
      children: [
        TCard(eyebrow: s.accountPrivacyBodyN0Eyebrow, children: [TToggleRow(fieldKey: 'account_privacy.cross_program_insights', label: s.accountPrivacyBodyN0ChildrenN0Label, sub: s.accountPrivacyBodyN0ChildrenN0Sub, value: true, bind: 'consents.cross_program_insights'), TToggleRow(fieldKey: 'account_privacy.de_identified_research', label: s.accountPrivacyBodyN0ChildrenN1Label, sub: s.accountPrivacyBodyN0ChildrenN1Sub, bind: 'consents.de_identified_research'), TToggleRow(fieldKey: 'account_privacy.anonymous_app_diagnostics', label: s.accountPrivacyBodyN0ChildrenN2Label, sub: s.accountPrivacyBodyN0ChildrenN2Sub, bind: 'consents.anonymous_app_diagnostics')]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: s.accountPrivacyBodyN1RowsN0Label, sub: s.accountPrivacyBodyN1RowsN0Sub, onTap: () => TNav.push(context, Routes.accountPrograms)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: s.accountPrivacyBodyN1RowsN1Label, sub: s.accountPrivacyBodyN1RowsN1Sub, onTap: () => TNav.toast(context, s.accountPrivacyBodyN1RowsN1ActionValue)), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: s.accountPrivacyBodyN1RowsN2Label, onTap: () => TNav.external(context, 'https://www.tetherhealthgroup.com/privacy/'))]),
        TBody(s.accountPrivacyBodyN2Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.accountPrivacyFooterN0Label, onPressed: () => TNav.submit(context, 'PATCH /v1/enrolments/consents', screenId: 'account_privacy', then: () => TNav.toast(context, s.accountPrivacyFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
