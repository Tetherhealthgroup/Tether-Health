// GENERATED from spec/screens/auth_social_new.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// New account from Apple or Google  ·  route `/auth/social/new`  ·  flow `auth`  ·  kind `screen`
/// Default state · phase account
/// Supabase signInWithIdToken (provider apple|google). First sign-in creates the identity, then onboarding starts with the account attached.
///
/// Actions (generated from spec/screens/auth_social_new.json):
///   • Back → back
///   • Create my account → POST supabase /auth/v1/token?grant_type=id_token then push → ob_programs
///   • Use a different account → back
/// API: POST supabase /auth/v1/token?grant_type=id_token
class AuthSocialNewScreen extends StatelessWidget {
  const AuthSocialNewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Create account'),
      children: [
        TIllustration(glyph: 'A'),
        TTitle('Create your Tether account?', size: TTitleSize.l, center: true),
        TBody('No Tether account uses this Apple ID or Google account yet.', tone: TTextTone.muted, center: true),
        TKeyValue(rows: [('Name', 'Alex (shared by Apple)'), ('Email', 'Private relay · Hide My Email'), ('Password', 'None needed')]),
        TBody('You can add email & password or another sign-in method later in Account → Sign-in methods.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Create my account', onPressed: () => TNav.submit(context, 'POST supabase /auth/v1/token?grant_type=id_token', screenId: 'auth_social_new', queueable: false, then: () => TNav.push(context, Routes.obPrograms)), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Use a different account', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
