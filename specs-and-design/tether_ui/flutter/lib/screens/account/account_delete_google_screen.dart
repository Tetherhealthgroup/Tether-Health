// GENERATED from spec/screens/account_delete_google.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Delete account · Google account  ·  route `/account/delete?state=google`  ·  flow `account`  ·  kind `screen`
/// State: Google account of account_delete · phase account
/// Copy needs clinical/legal review. Same as Delete account, with the password field replaced by native Google re-auth for the same provider; the returned user id must match the signed-in user. Delete runs only after Success.
///
/// Actions (generated from spec/screens/account_delete_google.json):
///   • Back → back
///   • Download a copy first → push → account_data
///   • Delete everything → auth (google): Sign in with Google result → Success: DELETE /v1/account/data then replace → account_deleted | Different account: toast “That’s a different Google account. Use the one you signed in with.” | Cancelled: toast “Nothing was deleted.” | Error: toast “Couldn’t reach Google. Nothing was deleted.”
/// API: DELETE /v1/account/data
class AccountDeleteGoogleScreen extends StatelessWidget {
  const AccountDeleteGoogleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.accountDeleteGoogleHeaderTitle),
      children: [
        TTitle(s.accountDeleteGoogleBodyN0Text),
        TBoundValues(keys: const ['account.data.programs', 'account.data.check_ins', 'account.data.readings', 'account.data.shared_summaries'], builder: (context, v) => TKeyValue(rows: [(s.accountDeleteGoogleBodyN1RowsN0N0, v.text('account.data.programs', '4')), (s.accountDeleteGoogleBodyN1RowsN1N0, v.text('account.data.check_ins', '63')), (s.accountDeleteGoogleBodyN1RowsN2N0, v.text('account.data.readings', '118')), (s.accountDeleteGoogleBodyN1RowsN3N0, v.text('account.data.shared_summaries', s.accountDeleteGoogleBodyN1RowsN3N1))])),
        TBody(s.accountDeleteGoogleBodyN2Text, tone: TTextTone.small),
        TButton(key: const ValueKey('a:body[3]'), label: s.accountDeleteGoogleBodyN3Label, onPressed: () => TNav.push(context, Routes.accountData), variant: TButtonVariant.secondary),
        TField(fieldKey: 'account_delete_google.type_delete_to_confirm', label: s.accountDeleteGoogleBodyN4Label, placeholder: s.accountDeleteGoogleBodyN4Placeholder),
        TCard(variant: TCardVariant.mint, eyebrow: s.accountDeleteGoogleBodyN5Eyebrow, title: s.accountDeleteGoogleBodyN5Title, text: s.accountDeleteGoogleBodyN5Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.accountDeleteGoogleFooterN0Label, onPressed: () => TNav.branch(context, 'Sign in with Google result', <String, VoidCallback>{'Success': () => TNav.submit(context, 'DELETE /v1/account/data', screenId: 'account_delete_google', then: () => TNav.replace(context, Routes.accountDeleted)), 'Different account': () => TNav.toast(context, s.accountDeleteGoogleFooterN0ActionCasesN1ActionValue), 'Cancelled': () => TNav.toast(context, s.accountDeleteGoogleFooterN0ActionCasesN2ActionValue), 'Error': () => TNav.toast(context, s.accountDeleteGoogleFooterN0ActionCasesN3ActionValue)}, provider: 'google'), variant: TButtonVariant.danger),
      ],
    );
  }
}
