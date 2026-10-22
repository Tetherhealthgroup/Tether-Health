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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.authVerifyHeaderTitle),
      children: [
        TIllustration(glyph: '@'),
        TTitle(s.authVerifyBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.authVerifyBodyN2Text, center: true),
        TCard(variant: TCardVariant.mint, text: s.authVerifyBodyN3Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.authVerifyFooterN0Label, onPressed: () => TNav.external(context, 'message://'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.authVerifyFooterN1Label, onPressed: () => TNav.push(context, Routes.authMerge), arrow: true),
        TLink(key: const ValueKey('a:footer[2]'), label: s.authVerifyFooterN2Label, onTap: () => TNav.toast(context, s.authVerifyFooterN2ActionValue)),
      ],
    );
  }
}
