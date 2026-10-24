// GENERATED from spec/screens/auth_session_apple.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Session expired · Apple account  ·  route `/auth/session?state=apple`  ·  flow `auth`  ·  kind `sheet`
/// State: Apple account of auth_session · phase account
/// Copy needs clinical/legal review. Same as Session expired, with the password field and Sign in button replaced by the native Apple button.
///
/// Actions (generated from spec/screens/auth_session_apple.json):
///   • Continue with Apple → auth (apple): Sign in with Apple result → Success: close | Cancelled: toast “Still signed out. Rescue works without signing in.” | Error: push → auth_social_error
///   • Use Face ID → close
/// API: —
class AuthSessionAppleScreen extends StatelessWidget {
  const AuthSessionAppleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TTitle(s.authSessionAppleBodyN0Text),
        TBody(s.authSessionAppleBodyN1Text, tone: TTextTone.muted),
        TBody(s.authSessionAppleBodyN2Text, tone: TTextTone.small),
      ],
      footer: [
        TAuthButtons(children: [TAuthButton(key: const ValueKey('a:footer[0].items[0]'), provider: 'apple', label: s.authSessionAppleFooterN0ItemsN0Label, onPressed: () => TNav.branch(context, 'Sign in with Apple result', <String, VoidCallback>{'Success': () => TNav.close(context), 'Cancelled': () => TNav.toast(context, s.authSessionAppleFooterN0ItemsN0ActionCasesN1ActionValue), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'apple'), platforms: ['ios'])]),
        TButton(key: const ValueKey('a:footer[1]'), label: s.authSessionAppleFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
