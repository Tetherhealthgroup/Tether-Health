// GENERATED from spec/screens/account.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Account  ·  route `/account`  ·  flow `account`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/account.json):
///   • Close → close
///   • Health records → push → records_hub
///   • Sign-in methods → push → account_signin_methods
///   • Programs & sharing → push → account_programs
///   • Notifications → push → account_notifications
///   • Privacy & consent → push → account_privacy
///   • Your data → push → account_data
///   • Text size & contrast → os_settings
///   • Language → toast “Language set to English”
///   • Help & legal → external https://www.tetherhealthgroup.com/support/
///   • Sign out → sheet → account_signout
/// API: —
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.accountHeaderTitle, left: THeaderLeft.close),
      children: [
        TListGroup(flat: true, rows: [TListRow(label: s.accountBodyN0RowsN0Label, sub: s.accountBodyN0RowsN0Sub, lead: TLead.avatar('A'))]),
        TListGroup(title: s.accountBodyN1Title, rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: s.accountBodyN1RowsN0Label, sub: s.accountBodyN1RowsN0Sub, onTap: () => TNav.push(context, Routes.recordsHub)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: s.accountBodyN1RowsN1Label, sub: s.accountBodyN1RowsN1Sub, onTap: () => TNav.push(context, Routes.accountSigninMethods))]),
        TListGroup(title: s.accountBodyN2Title, rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.accountBodyN2RowsN0Label, sub: s.accountBodyN2RowsN0Sub, onTap: () => TNav.push(context, Routes.accountPrograms)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.accountBodyN2RowsN1Label, sub: s.accountBodyN2RowsN1Sub, onTap: () => TNav.push(context, Routes.accountNotifications)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.accountBodyN2RowsN2Label, sub: s.accountBodyN2RowsN2Sub, onTap: () => TNav.push(context, Routes.accountPrivacy)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: s.accountBodyN2RowsN3Label, sub: s.accountBodyN2RowsN3Sub, onTap: () => TNav.push(context, Routes.accountData))]),
        TListGroup(title: s.accountBodyN3Title, rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: s.accountBodyN3RowsN0Label, sub: s.accountBodyN3RowsN0Sub, onTap: () => TNav.osSettings(context)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: s.accountBodyN3RowsN1Label, sub: s.accountBodyN3RowsN1Sub, onTap: () => TNav.toast(context, s.accountBodyN3RowsN1ActionValue)), TListRow(key: const ValueKey('a:body[3].rows[2]'), label: s.accountBodyN3RowsN2Label, onTap: () => TNav.external(context, 'https://www.tetherhealthgroup.com/support/'))]),
        TBody(s.accountBodyN4Text, tone: TTextTone.small, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.accountFooterN0Label, onPressed: () => TNav.sheet(context, Routes.accountSignout), variant: TButtonVariant.secondary),
      ],
    );
  }
}
