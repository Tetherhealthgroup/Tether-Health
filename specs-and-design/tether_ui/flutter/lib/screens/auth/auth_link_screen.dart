// GENERATED from spec/screens/auth_link.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Link accounts  ·  route `/auth/link`  ·  flow `auth`  ·  kind `screen`
/// Default state · phase account
/// Prevents duplicate accounts for the same email. Supabase manual identity linking after password re-auth.
///
/// Actions (generated from spec/screens/auth_link.json):
///   • Back → back
///   • Forgot password? → push → auth_forgot
///   • Link and sign in → POST supabase /auth/v1/user/identities (linkIdentity) then reset → today
///   • Cancel → back
/// API: —
class AuthLinkScreen extends StatelessWidget {
  const AuthLinkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.authLinkHeaderTitle),
      children: [
        TIllustration(glyph: '⇄'),
        TTitle(s.authLinkBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.authLinkBodyN2Text, tone: TTextTone.muted, center: true),
        TField(fieldKey: 'auth_link.password', label: s.authLinkBodyN3Label, placeholder: '••••••••••••', kind: TFieldKind.password),
        TLink(key: const ValueKey('a:body[4]'), label: s.authLinkBodyN4Label, onTap: () => TNav.push(context, Routes.authForgot)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.authLinkFooterN0Label, onPressed: () => TNav.submit(context, 'POST supabase /auth/v1/user/identities (linkIdentity)', screenId: 'auth_link', queueable: false, then: () => TNav.reset(context, Routes.today)), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.authLinkFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
