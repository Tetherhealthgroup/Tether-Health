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
    return TSheet(
      children: [
        TTitle('Please sign in again'),
        TBody('For your security, sessions end after 30 days. Anything you logged offline is kept and syncs after you sign in.', tone: TTextTone.muted),
        TField(fieldKey: 'auth_session.password', label: 'Password', placeholder: 'Password', kind: TFieldKind.password),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Sign in', onPressed: () => TNav.submit(context, 'POST supabase /auth/v1/token', then: () => TNav.close(context)), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Use Face ID', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
