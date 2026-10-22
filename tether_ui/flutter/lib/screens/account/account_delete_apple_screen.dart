// GENERATED from spec/screens/account_delete_apple.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Delete account · Apple account  ·  route `/account/delete?state=apple`  ·  flow `account`  ·  kind `screen`
/// State: Apple account of account_delete · phase account
/// Copy needs clinical/legal review. Same as Delete account, with the password field replaced by native Apple re-auth for the same provider; the returned user id must match the signed-in user. Delete runs only after Success.
///
/// Actions (generated from spec/screens/account_delete_apple.json):
///   • Back → back
///   • Download a copy first → push → account_data
///   • Delete everything → auth (apple): Sign in with Apple result → Success: DELETE /v1/account/data then replace → account_deleted | Different account: toast “That’s a different Apple account. Use the one you signed in with.” | Cancelled: toast “Nothing was deleted.” | Error: toast “Couldn’t reach Apple. Nothing was deleted.”
/// API: DELETE /v1/account/data
class AccountDeleteAppleScreen extends StatelessWidget {
  const AccountDeleteAppleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.accountDeleteAppleHeaderTitle),
      children: [
        TTitle(s.accountDeleteAppleBodyN0Text),
        TKeyValue(rows: [(s.accountDeleteAppleBodyN1RowsN0N0, '4'), (s.accountDeleteAppleBodyN1RowsN1N0, '63'), (s.accountDeleteAppleBodyN1RowsN2N0, '118'), (s.accountDeleteAppleBodyN1RowsN3N0, s.accountDeleteAppleBodyN1RowsN3N1)]),
        TBody(s.accountDeleteAppleBodyN2Text, tone: TTextTone.small),
        TButton(key: const ValueKey('a:body[3]'), label: s.accountDeleteAppleBodyN3Label, onPressed: () => TNav.push(context, Routes.accountData), variant: TButtonVariant.secondary),
        TField(fieldKey: 'account_delete_apple.type_delete_to_confirm', label: s.accountDeleteAppleBodyN4Label, placeholder: s.accountDeleteAppleBodyN4Placeholder),
        TCard(variant: TCardVariant.mint, eyebrow: s.accountDeleteAppleBodyN5Eyebrow, title: s.accountDeleteAppleBodyN5Title, text: s.accountDeleteAppleBodyN5Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.accountDeleteAppleFooterN0Label, onPressed: () => TNav.branch(context, 'Sign in with Apple result', <String, VoidCallback>{'Success': () => TNav.submit(context, 'DELETE /v1/account/data', screenId: 'account_delete_apple', then: () => TNav.replace(context, Routes.accountDeleted)), 'Different account': () => TNav.toast(context, s.accountDeleteAppleFooterN0ActionCasesN1ActionValue), 'Cancelled': () => TNav.toast(context, s.accountDeleteAppleFooterN0ActionCasesN2ActionValue), 'Error': () => TNav.toast(context, s.accountDeleteAppleFooterN0ActionCasesN3ActionValue)}, provider: 'apple'), variant: TButtonVariant.danger),
      ],
    );
  }
}
