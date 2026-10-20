// GENERATED from spec/screens/auth_newpass.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Set new password  ·  route `/auth/reset`  ·  flow `auth`  ·  kind `screen`
/// Default state · phase account
/// Opened from the reset email deep link.
///
/// Actions (generated from spec/screens/auth_newpass.json):
///   • Close → close
///   • Save password → PUT supabase /auth/v1/user then reset → today
/// API: —
class AuthNewpassScreen extends StatelessWidget {
  const AuthNewpassScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'New password', left: THeaderLeft.close),
      children: [
        TTitle('Choose a new password'),
        TField(fieldKey: 'auth_newpass.new_password', label: 'New password', hint: 'At least 12 characters.', placeholder: '••••••••••••', kind: TFieldKind.password),
        TField(fieldKey: 'auth_newpass.confirm_password', label: 'Confirm password', placeholder: '••••••••••••', kind: TFieldKind.password),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save password', onPressed: () => TNav.submit(context, 'PUT supabase /auth/v1/user', screenId: 'auth_newpass', queueable: false, then: () => TNav.reset(context, Routes.today)), arrow: true),
      ],
    );
  }
}
