// GENERATED from spec/screens/auth_session.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Session expired  ·  route `/auth/session`  ·  flow `auth`  ·  kind `sheet`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/auth_session.json):
///   • Sign in → POST supabase /auth/v1/token then close
///   • Use Face ID → close
/// API: —
class AuthSessionScreen extends StatelessWidget {
  const AuthSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TTitle(s.authSessionBodyN0Text),
        TBody(s.authSessionBodyN1Text, tone: TTextTone.muted),
        TField(fieldKey: 'auth_session.password', label: s.authSessionBodyN2Label, placeholder: s.authSessionBodyN2Placeholder, kind: TFieldKind.password),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.authSessionFooterN0Label, onPressed: () => TNav.submit(context, 'POST supabase /auth/v1/token', screenId: 'auth_session', queueable: false, then: () => TNav.close(context)), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.authSessionFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
