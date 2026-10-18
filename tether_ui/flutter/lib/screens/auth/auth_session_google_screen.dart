// GENERATED from spec/screens/auth_session_google.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Session expired · Google account  ·  route `/auth/session?state=google`  ·  flow `auth`  ·  kind `sheet`
/// State: Google account of auth_session · phase account
/// Copy needs clinical/legal review. Same as Session expired, with the password field and Sign in button replaced by the native Google button.
///
/// Actions (generated from spec/screens/auth_session_google.json):
///   • Continue with Google → auth (google): Sign in with Google result → Success: close | Cancelled: toast “Still signed out. Rescue works without signing in.” | Error: push → auth_social_error
///   • Use Face ID → close
/// API: POST supabase /auth/v1/token?grant_type=id_token
class AuthSessionGoogleScreen extends StatelessWidget {
  const AuthSessionGoogleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      children: [
        TTitle('Please sign in again'),
        TBody('For your security, sessions end after 30 days.', tone: TTextTone.muted),
        TBody('You signed in with Google, so there’s no password to type.', tone: TTextTone.small),
      ],
      footer: [
        TAuthButtons(children: [TAuthButton(key: const ValueKey('a:footer[0].items[0]'), provider: 'google', label: 'Continue with Google', onPressed: () => TNav.branch(context, 'Sign in with Google result', <String, VoidCallback>{'Success': () => TNav.close(context), 'Cancelled': () => TNav.toast(context, 'Still signed out. Rescue works without signing in.'), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'google'), platforms: ['ios', 'android'])]),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Use Face ID', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
