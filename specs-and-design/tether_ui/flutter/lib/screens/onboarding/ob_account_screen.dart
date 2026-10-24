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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.obAccountHeaderTitle, left: THeaderLeft.close),
      children: [
        TTitle(s.obAccountBodyN0Text),
        TBody(s.obAccountBodyN1Text, tone: TTextTone.muted),
        TAuthButtons(children: [TAuthButton(key: const ValueKey('a:body[2].items[0]'), provider: 'apple', label: s.obAccountBodyN2ItemsN0Label, onPressed: () => TNav.branch(context, '“I’m 18 or older” ticked?', <String, VoidCallback>{'Age confirmed': () => TNav.branch(context, 'Sign in with Apple result', <String, VoidCallback>{'Success': () => TNav.push(context, Routes.authMerge), 'Email already has a Tether account': () => TNav.push(context, Routes.authLink), 'Cancelled': () => TNav.toast(context, s.obAccountBodyN2ItemsN0ActionCasesN0ActionCasesN2ActionValue), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'apple'), 'Age not confirmed': () => TNav.toast(context, s.obAccountBodyN2ItemsN0ActionCasesN1ActionValue)}, decide: 'ob.age'), platforms: ['ios']), TAuthButton(key: const ValueKey('a:body[2].items[1]'), provider: 'google', label: s.obAccountBodyN2ItemsN1Label, onPressed: () => TNav.branch(context, '“I’m 18 or older” ticked?', <String, VoidCallback>{'Age confirmed': () => TNav.branch(context, 'Sign in with Google result', <String, VoidCallback>{'Success': () => TNav.push(context, Routes.authMerge), 'Email already has a Tether account': () => TNav.push(context, Routes.authLink), 'Cancelled': () => TNav.toast(context, s.obAccountBodyN2ItemsN1ActionCasesN0ActionCasesN2ActionValue), 'Error': () => TNav.push(context, Routes.authSocialError)}, provider: 'google'), 'Age not confirmed': () => TNav.toast(context, s.obAccountBodyN2ItemsN1ActionCasesN1ActionValue)}, decide: 'ob.age'), platforms: ['ios', 'android'])]),
        TBody(s.obAccountBodyN3Text, tone: TTextTone.small),
        TEyebrow(s.obAccountBodyN4Text),
        TField(fieldKey: 'ob_account.email', label: s.obAccountBodyN5Label, placeholder: s.obAccountBodyN5Placeholder, kind: TFieldKind.email),
        TField(fieldKey: 'ob_account.password', label: s.obAccountBodyN6Label, hint: s.obAccountBodyN6Hint, placeholder: '••••••••••••', kind: TFieldKind.password),
        TChecklist(fieldKey: 'ob_account.age_18_or_older', items: [TCheckItem(s.obAccountBodyN7ItemsN0Label, value: 'I’m 18 or older')]),
        TBody(s.obAccountBodyN8Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.obAccountFooterN0Label, onPressed: () => TNav.branch(context, '“I’m 18 or older” ticked?', <String, VoidCallback>{'Age confirmed': () => TNav.submit(context, 'POST supabase /auth/v1/signup', screenId: 'ob_account', queueable: false, then: () => TNav.push(context, Routes.authVerify)), 'Age not confirmed': () => TNav.toast(context, s.obAccountFooterN0ActionCasesN1ActionValue)}, decide: 'ob.age'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.obAccountFooterN1Label, onPressed: () => TNav.branch(context, '“I’m 18 or older” ticked?', <String, VoidCallback>{'Age confirmed': () => TNav.reset(context, Routes.today), 'Age not confirmed': () => TNav.toast(context, s.obAccountFooterN1ActionCasesN1ActionValue)}, decide: 'ob.age'), variant: TButtonVariant.secondary),
      ],
    );
  }
}
