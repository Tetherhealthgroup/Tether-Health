// GENERATED from spec/screens/ob_account.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Save your progress  ·  route `/onboarding/account`  ·  flow `onboarding`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/ob_account.json):
///   • Close → close
///   • Continue with Apple → decide ob.age: “I’m 18 or older” ticked? → Age confirmed: auth (apple): Sign in with Apple result → Success: push → auth_merge | Email already has a Tether account: push → auth_link | Cancelled: toast “Sign-in cancelled” | Error: push → auth_social_error | Age not confirmed: toast “You need to be 18 or older to continue.”
///   • Continue with Google → decide ob.age: “I’m 18 or older” ticked? → Age confirmed: auth (google): Sign in with Google result → Success: push → auth_merge | Email already has a Tether account: push → auth_link | Cancelled: toast “Sign-in cancelled” | Error: push → auth_social_error | Age not confirmed: toast “You need to be 18 or older to continue.”
///   • Create account → decide ob.age: “I’m 18 or older” ticked? → Age confirmed: POST supabase /auth/v1/signup then push → auth_verify | Age not confirmed: toast “You need to be 18 or older to continue.”
///   • Continue on this phone only → decide ob.age: “I’m 18 or older” ticked? → Age confirmed: reset → today | Age not confirmed: toast “You need to be 18 or older to continue.”
/// API: POST supabase /auth/v1/signup
class ObAccountScreen extends StatelessWidget {
  const ObAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Save your progress', left: THeaderLeft.close),
      children: [
        TTitle('Create your account'),
        TBody('Keeps your plans safe if you change phones. You can also continue on this phone only.', tone: TTextTone.muted),
        TAuthButtons(children: [TAuthButton(key: const ValueKey('a:body[2].items[0]'), provider: 'apple', label: 'Continue with Apple', onPressed: () => TNav.branch(context, '“I’m 18 or older” ticked?', <String, VoidCallback>{'Age confirmed': () => TNav.branch(context, 'Sign in with Apple result', <String, VoidCallback>{'Success': () => TNav.push(context, Routes.authMerge), 'Email already has a Tether account': () => TNav.push(context, Routes.authLink), 'Cancelled': () => TNav.toast(context, 'Sign-in cancelled'), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'apple'), 'Age not confirmed': () => TNav.toast(context, 'You need to be 18 or older to continue.')}, decide: 'ob.age'), platforms: ['ios']), TAuthButton(key: const ValueKey('a:body[2].items[1]'), provider: 'google', label: 'Continue with Google', onPressed: () => TNav.branch(context, '“I’m 18 or older” ticked?', <String, VoidCallback>{'Age confirmed': () => TNav.branch(context, 'Sign in with Google result', <String, VoidCallback>{'Success': () => TNav.push(context, Routes.authMerge), 'Email already has a Tether account': () => TNav.push(context, Routes.authLink), 'Cancelled': () => TNav.toast(context, 'Sign-in cancelled'), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'google'), 'Age not confirmed': () => TNav.toast(context, 'You need to be 18 or older to continue.')}, decide: 'ob.age'), platforms: ['ios', 'android'])]),
        TBody('Sign in with Apple can hide your email: we use Apple’s private relay address.', tone: TTextTone.small),
        TEyebrow('Or with email'),
        TField(fieldKey: 'ob_account.email', label: 'Email', placeholder: 'alex@example.com', kind: TFieldKind.email),
        TField(fieldKey: 'ob_account.password', label: 'Password', hint: 'At least 12 characters. A passphrase works well.', placeholder: '••••••••••••', kind: TFieldKind.password),
        TChecklist(fieldKey: 'ob_account.age_18_or_older', items: [TCheckItem('I’m 18 or older')]),
        TBody('Guest plans are encrypted on this phone. If you sign up later, we ask before uploading them.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Create account', onPressed: () => TNav.branch(context, '“I’m 18 or older” ticked?', <String, VoidCallback>{'Age confirmed': () => TNav.submit(context, 'POST supabase /auth/v1/signup', screenId: 'ob_account', queueable: false, then: () => TNav.push(context, Routes.authVerify)), 'Age not confirmed': () => TNav.toast(context, 'You need to be 18 or older to continue.')}, decide: 'ob.age'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Continue on this phone only', onPressed: () => TNav.branch(context, '“I’m 18 or older” ticked?', <String, VoidCallback>{'Age confirmed': () => TNav.reset(context, Routes.today), 'Age not confirmed': () => TNav.toast(context, 'You need to be 18 or older to continue.')}, decide: 'ob.age'), variant: TButtonVariant.secondary),
      ],
    );
  }
}
