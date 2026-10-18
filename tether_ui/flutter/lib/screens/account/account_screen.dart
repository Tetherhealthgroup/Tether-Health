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
    return TScreen(
      header: THeader(title: 'Account', left: THeaderLeft.close),
      children: [
        TListGroup(flat: true, rows: [TListRow(label: 'Alex', sub: 'alex@example.com', lead: TLead.avatar('A'))]),
        TListGroup(title: 'Your health data', rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'Health records', sub: '2 sources · Epic, Medicare', onTap: () => TNav.push(context, Routes.recordsHub)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'Sign-in methods', sub: 'Apple · email', onTap: () => TNav.push(context, Routes.accountSigninMethods))]),
        TListGroup(title: 'Settings', rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Programs & sharing', sub: '2 focus · 1 learn · 1 paused', onTap: () => TNav.push(context, Routes.accountPrograms)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Notifications', sub: 'On · quiet hours 9 PM–7 AM', onTap: () => TNav.push(context, Routes.accountNotifications)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Privacy & consent', sub: 'Reviewed Aug 22, 2026', onTap: () => TNav.push(context, Routes.accountPrivacy)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Your data', sub: 'Export or delete', onTap: () => TNav.push(context, Routes.accountData))]),
        TListGroup(title: 'App', rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'Text size & contrast', sub: 'Follows your phone', onTap: () => TNav.osSettings(context)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'Language', sub: 'English', onTap: () => TNav.toast(context, 'Language set to English')), TListRow(key: const ValueKey('a:body[3].rows[2]'), label: 'Help & legal', onTap: () => TNav.external(context, 'https://www.tetherhealthgroup.com/support/'))]),
        TBody('Tether Health 1.0.0 (100)', tone: TTextTone.small, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Sign out', onPressed: () => TNav.sheet(context, Routes.accountSignout), variant: TButtonVariant.secondary),
      ],
    );
  }
}
