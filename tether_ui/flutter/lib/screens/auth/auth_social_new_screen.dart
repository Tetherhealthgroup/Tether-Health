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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.authSocialNewHeaderTitle),
      children: [
        TIllustration(glyph: 'A'),
        TTitle(s.authSocialNewBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.authSocialNewBodyN2Text, tone: TTextTone.muted, center: true),
        TKeyValue(rows: [(s.authSocialNewBodyN3RowsN0N0, s.authSocialNewBodyN3RowsN0N1), (s.authSocialNewBodyN3RowsN1N0, s.authSocialNewBodyN3RowsN1N1), (s.authSocialNewBodyN3RowsN2N0, s.authSocialNewBodyN3RowsN2N1)]),
        TBody(s.authSocialNewBodyN4Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.authSocialNewFooterN0Label, onPressed: () => TNav.push(context, Routes.obPrograms), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.authSocialNewFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
