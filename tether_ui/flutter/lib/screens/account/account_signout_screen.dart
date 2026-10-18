// GENERATED from spec/screens/account_signout.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Sign out  ·  route `/account/signout`  ·  flow `account`  ·  kind `sheet`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/account_signout.json):
///   • Sign out → reset → welcome
///   • Cancel → close
/// API: —
class AccountSignoutScreen extends StatelessWidget {
  const AccountSignoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      children: [
        TTitle('Sign out of Tether?'),
        TBody('Encrypted program data on this phone is removed. Your account data stays safe in the cloud.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Sign out', onPressed: () => TNav.reset(context, Routes.welcome), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
