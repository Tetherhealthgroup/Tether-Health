// GENERATED from spec/screens/account_signin_methods.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Sign-in methods  ·  route `/account/sign-in`  ·  flow `account`  ·  kind `screen`
/// Default state · phase account
/// iPhone shows Apple first (App Store rule 4.8 when Google is offered); Android shows Google.
///
/// Actions (generated from spec/screens/account_signin_methods.json):
///   • Back → back
///   • Google → auth (google): Sign in with Google result → Success: toast “Google connected” | Email already has a Tether account: push → auth_link | Cancelled: toast “Cancelled” | Error: push → auth_social_error
///   • Email & password → push → auth_newpass
/// API: —
class AccountSigninMethodsScreen extends StatelessWidget {
  const AccountSigninMethodsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Sign-in methods'),
      children: [
        TBody('Use any connected method to sign in. Keep at least one.', tone: TTextTone.muted),
        TListGroup(rows: [TListRow(label: 'Apple', sub: 'Connected · Hide My Email', lead: TLead.icon(''), pill: 'Primary'), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'Google', sub: 'Not connected', lead: TLead.icon('G'), onTap: () => TNav.branch(context, 'Sign in with Google result', <String, VoidCallback>{'Success': () => TNav.toast(context, 'Google connected'), 'Email already has a Tether account': () => TNav.push(context, Routes.authLink), 'Cancelled': () => TNav.toast(context, 'Cancelled'), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'google')), TListRow(key: const ValueKey('a:body[1].rows[2]'), label: 'Email & password', sub: 'alex@example.com · set a password', lead: TLead.icon('@'), onTap: () => TNav.push(context, Routes.authNewpass))]),
        TCard(variant: TCardVariant.mint, text: 'To remove Apple, add another method first. Removing a method never deletes your data.'),
      ],
    );
  }
}
