// GENERATED from spec/screens/auth_social_new.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// New account from Apple or Google  ·  route `/auth/social/new`  ·  flow `auth`  ·  kind `screen`
/// Default state · phase account
/// Not routed (P-73): a new Apple ID or Google account goes through the normal sign-up from its start (ob_programs). Kept as the approved design; Create my account opens the normal sign-up and creates nothing here.
///
/// Actions (generated from spec/screens/auth_social_new.json):
///   • Back → back
///   • Create my account → push → ob_programs
///   • Use a different account → back
/// API: —
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
        TButton(key: const ValueKey('a:footer[0]'), label: 'Create my account', onPressed: () => TNav.push(context, Routes.obPrograms), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Use a different account', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
