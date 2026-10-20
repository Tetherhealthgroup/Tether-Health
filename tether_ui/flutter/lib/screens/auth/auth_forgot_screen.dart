// GENERATED from spec/screens/auth_forgot.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Reset password  ·  route `/auth/forgot`  ·  flow `auth`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/auth_forgot.json):
///   • Back → back
///   • Send reset link → POST supabase /auth/v1/recover then replace → auth_forgot_sent
/// API: —
class AuthForgotScreen extends StatelessWidget {
  const AuthForgotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Reset password'),
      children: [
        TTitle('Forgot your password?'),
        TBody('Enter your email and we’ll send a reset link.', tone: TTextTone.muted),
        TField(fieldKey: 'auth_forgot.email', label: 'Email', placeholder: 'alex@example.com', kind: TFieldKind.email),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Send reset link', onPressed: () => TNav.submit(context, 'POST supabase /auth/v1/recover', screenId: 'auth_forgot', queueable: false, then: () => TNav.replace(context, Routes.authForgotSent)), arrow: true),
      ],
    );
  }
}
