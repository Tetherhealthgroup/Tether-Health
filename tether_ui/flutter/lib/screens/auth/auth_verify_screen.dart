// GENERATED from spec/screens/auth_verify.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Verify email  ·  route `/auth/verify`  ·  flow `auth`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/auth_verify.json):
///   • Back → back
///   • Open email app → external message://
///   • I’ve confirmed my email → push → auth_merge
///   • Resend link (available in 0:42) → toast “Link sent again”
/// API: —
class AuthVerifyScreen extends StatelessWidget {
  const AuthVerifyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Check your email'),
      children: [
        TIllustration(glyph: '@'),
        TTitle('Confirm your email', size: TTitleSize.l, center: true),
        TBody('We sent a link to alex@example.com. Open it on this phone to finish.', center: true),
        TCard(variant: TCardVariant.mint, text: 'Your plan is saved on this phone while you wait. Nothing is lost if you close the app.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Open email app', onPressed: () => TNav.external(context, 'message://'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'I’ve confirmed my email', onPressed: () => TNav.push(context, Routes.authMerge), arrow: true),
        TLink(key: const ValueKey('a:footer[2]'), label: 'Resend link (available in 0:42)', onTap: () => TNav.toast(context, 'Link sent again')),
      ],
    );
  }
}
