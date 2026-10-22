// GENERATED from spec/screens/auth_social_error.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Apple / Google sign-in failed  ·  route `/auth/social/error`  ·  flow `auth`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/auth_social_error.json):
///   • Close → close
///   • Try again → auth (google): Sign in with Google result → Success: reset → today | Error: toast “Still can’t reach Google. Try email.”
///   • Use email instead → replace → auth_signin
/// API: —
class AuthSocialErrorScreen extends StatelessWidget {
  const AuthSocialErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.authSocialErrorHeaderTitle, left: THeaderLeft.close),
      children: [
        TIllustration(glyph: '!', tone: TTone.error),
        TTitle(s.authSocialErrorBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.authSocialErrorBodyN2Text, tone: TTextTone.muted, center: true),
        TBody(s.authSocialErrorBodyN3Text, tone: TTextTone.small, center: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.authSocialErrorFooterN0Label, onPressed: () => TNav.branch(context, 'Sign in with Google result', <String, VoidCallback>{'Success': () => TNav.reset(context, Routes.today), 'Error': () => TNav.toast(context, s.authSocialErrorFooterN0ActionCasesN1ActionValue)}, provider: 'google'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.authSocialErrorFooterN1Label, onPressed: () => TNav.replace(context, Routes.authSignin), variant: TButtonVariant.secondary),
      ],
    );
  }
}
