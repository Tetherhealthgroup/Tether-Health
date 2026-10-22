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
///   • Continue with Apple → auth (apple): Sign in with Apple result → Success: reset → today | Success · guest plan on phone: push → auth_merge | New Apple ID, no Tether account: replace → ob_programs | Cancelled: toast “Sign-in cancelled” | Error: push → auth_social_error
///   • Continue with Google → auth (google): Sign in with Google result → Success: reset → today | Success · guest plan on phone: push → auth_merge | New Google account, no Tether account: replace → ob_programs | Cancelled: toast “Sign-in cancelled” | Error: push → auth_social_error
///   • Forgot password? → push → auth_forgot
///   • Try again → POST supabase /auth/v1/token then branch: Sign-in result → Success: reset → today | Success · guest plan on phone: push → auth_merge | Wrong password: replace → auth_signin_error
///   • Cancel → close
/// API: —
class AuthSigninErrorScreen extends StatelessWidget {
  const AuthSigninErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TTitle(s.authSigninErrorBodyN0Text),
        TBanner(kind: TBannerKind.error, text: s.authSigninErrorBodyN1Text),
        TAuthButtons(children: [TAuthButton(key: const ValueKey('a:body[2].items[0]'), provider: 'apple', label: s.authSigninErrorBodyN2ItemsN0Label, onPressed: () => TNav.branch(context, 'Sign in with Apple result', <String, VoidCallback>{'Success': () => TNav.reset(context, Routes.today), 'Success · guest plan on phone': () => TNav.push(context, Routes.authMerge), 'New Apple ID, no Tether account': () => TNav.replace(context, Routes.obPrograms), 'Cancelled': () => TNav.toast(context, s.authSigninErrorBodyN2ItemsN0ActionCasesN3ActionValue), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'apple'), platforms: ['ios']), TAuthButton(key: const ValueKey('a:body[2].items[1]'), provider: 'google', label: s.authSigninErrorBodyN2ItemsN1Label, onPressed: () => TNav.branch(context, 'Sign in with Google result', <String, VoidCallback>{'Success': () => TNav.reset(context, Routes.today), 'Success · guest plan on phone': () => TNav.push(context, Routes.authMerge), 'New Google account, no Tether account': () => TNav.replace(context, Routes.obPrograms), 'Cancelled': () => TNav.toast(context, s.authSigninErrorBodyN2ItemsN1ActionCasesN3ActionValue), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'google'), platforms: ['ios', 'android'])]),
        TEyebrow(s.authSigninErrorBodyN3Text),
        TField(fieldKey: 'auth_signin_error.email', label: s.authSigninErrorBodyN4Label, placeholder: s.authSigninErrorBodyN4Placeholder, kind: TFieldKind.email),
        TField(fieldKey: 'auth_signin_error.password', label: s.authSigninErrorBodyN5Label, error: s.authSigninErrorBodyN5Error, placeholder: '••••••••', kind: TFieldKind.password),
        TLink(key: const ValueKey('a:body[6]'), label: s.authSigninErrorBodyN6Label, onTap: () => TNav.push(context, Routes.authForgot), alignLeft: true),
        TBody(s.authSigninErrorBodyN7Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.authSigninErrorFooterN0Label, onPressed: () => TNav.submit(context, 'POST supabase /auth/v1/token', screenId: 'auth_signin_error', queueable: false, then: () => TNav.branch(context, 'Sign-in result', <String, VoidCallback>{'Success': () => TNav.reset(context, Routes.today), 'Success · guest plan on phone': () => TNav.push(context, Routes.authMerge), 'Wrong password': () => TNav.replace(context, Routes.authSigninError)})), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.authSigninErrorFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
