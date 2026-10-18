// GENERATED from spec/screens/auth_signin_error.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Sign-in error  ·  route `/auth/signin?state=error`  ·  flow `auth`  ·  kind `sheet`
/// State: error of auth_signin · phase account
/// 
///
/// Actions (generated from spec/screens/auth_signin_error.json):
///   • Continue with Apple → auth (apple): Sign in with Apple result → Success: reset → today | Success · guest plan on phone: push → auth_merge | New Apple ID, no Tether account: push → auth_social_new | Cancelled: toast “Sign-in cancelled” | Error: push → auth_social_error
///   • Continue with Google → auth (google): Sign in with Google result → Success: reset → today | Success · guest plan on phone: push → auth_merge | New Google account, no Tether account: push → auth_social_new | Cancelled: toast “Sign-in cancelled” | Error: push → auth_social_error
///   • Forgot password? → push → auth_forgot
///   • Try again → branch: Sign-in result → Success: reset → today | Wrong password: replace → auth_signin_error
///   • Cancel → close
/// API: —
class AuthSigninErrorScreen extends StatelessWidget {
  const AuthSigninErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      children: [
        TTitle('Welcome back'),
        TBanner(kind: TBannerKind.error, text: 'That email and password don’t match. Check both and try again.'),
        TAuthButtons(children: [TAuthButton(key: const ValueKey('a:body[2].items[0]'), provider: 'apple', label: 'Continue with Apple', onPressed: () => TNav.branch(context, 'Sign in with Apple result', <String, VoidCallback>{'Success': () => TNav.reset(context, Routes.today), 'Success · guest plan on phone': () => TNav.push(context, Routes.authMerge), 'New Apple ID, no Tether account': () => TNav.push(context, Routes.authSocialNew), 'Cancelled': () => TNav.toast(context, 'Sign-in cancelled'), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'apple'), platforms: ['ios']), TAuthButton(key: const ValueKey('a:body[2].items[1]'), provider: 'google', label: 'Continue with Google', onPressed: () => TNav.branch(context, 'Sign in with Google result', <String, VoidCallback>{'Success': () => TNav.reset(context, Routes.today), 'Success · guest plan on phone': () => TNav.push(context, Routes.authMerge), 'New Google account, no Tether account': () => TNav.push(context, Routes.authSocialNew), 'Cancelled': () => TNav.toast(context, 'Sign-in cancelled'), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'google'), platforms: ['ios', 'android'])]),
        TEyebrow('Or with email'),
        TField(fieldKey: 'auth_signin_error.email', label: 'Email', value: 'alex@example.com', kind: TFieldKind.email),
        TField(fieldKey: 'auth_signin_error.password', label: 'Password', value: '••••••••', error: 'Password is incorrect.', kind: TFieldKind.password),
        TLink(key: const ValueKey('a:body[6]'), label: 'Forgot password?', onTap: () => TNav.push(context, Routes.authForgot), alignLeft: true),
        TBody('After 5 tries we pause sign-in for 15 minutes to protect your account.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Try again', onPressed: () => TNav.branch(context, 'Sign-in result', <String, VoidCallback>{'Success': () => TNav.reset(context, Routes.today), 'Wrong password': () => TNav.replace(context, Routes.authSigninError)}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
