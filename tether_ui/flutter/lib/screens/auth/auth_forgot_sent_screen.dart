// GENERATED from spec/screens/auth_forgot_sent.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Reset link sent  ·  route `/auth/forgot/sent`  ·  flow `auth`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/auth_forgot_sent.json):
///   • Back → back
///   • Back to welcome → reset → welcome
/// API: —
class AuthForgotSentScreen extends StatelessWidget {
  const AuthForgotSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Reset password'),
      children: [
        TIllustration(glyph: '✓'),
        TTitle('Check your email', size: TTitleSize.l, center: true),
        TBody('If an account exists for that address, a reset link is on its way. It expires in 1 hour.', center: true),
        TBody('We never say whether an email is registered, to protect your privacy.', tone: TTextTone.small, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Back to welcome', onPressed: () => TNav.reset(context, Routes.welcome), variant: TButtonVariant.secondary),
      ],
    );
  }
}
