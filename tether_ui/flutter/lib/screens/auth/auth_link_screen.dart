// GENERATED from spec/screens/auth_link.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Link accounts  ·  route `/auth/link`  ·  flow `auth`  ·  kind `screen`
/// Default state · phase account
/// Prevents duplicate accounts for the same email. Supabase manual identity linking after password re-auth.
///
/// Actions (generated from spec/screens/auth_link.json):
///   • Back → back
///   • Forgot password? → push → auth_forgot
///   • Link and sign in → POST supabase /auth/v1/user/identities (linkIdentity) then reset → today
///   • Cancel → back
/// API: —
class AuthLinkScreen extends StatelessWidget {
  const AuthLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Link accounts'),
      children: [
        TIllustration(glyph: '⇄'),
        TTitle('You already have a Tether account', size: TTitleSize.l, center: true),
        TBody('alex@example.com signed up with email and password. Enter your password once to link Google. After that, either sign-in works.', tone: TTextTone.muted, center: true),
        TField(fieldKey: 'auth_link.password', label: 'Password', value: '••••••••••••', kind: TFieldKind.password),
        TLink(key: const ValueKey('a:body[4]'), label: 'Forgot password?', onTap: () => TNav.push(context, Routes.authForgot)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Link and sign in', onPressed: () => TNav.submit(context, 'POST supabase /auth/v1/user/identities (linkIdentity)', then: () => TNav.reset(context, Routes.today)), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
