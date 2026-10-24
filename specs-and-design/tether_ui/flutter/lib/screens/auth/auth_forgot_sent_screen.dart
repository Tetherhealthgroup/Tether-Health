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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.authForgotSentHeaderTitle),
      children: [
        TIllustration(glyph: '✓'),
        TTitle(s.authForgotSentBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.authForgotSentBodyN2Text, center: true),
        TBody(s.authForgotSentBodyN3Text, tone: TTextTone.small, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.authForgotSentFooterN0Label, onPressed: () => TNav.reset(context, Routes.welcome), variant: TButtonVariant.secondary),
      ],
    );
  }
}
