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
    return TScreen(
      header: THeader(title: 'Delete account'),
      children: [
        TTitle('Delete your account and all data?'),
        TKeyValue(rows: [('Programs', '4'), ('Check-ins', '63'), ('Readings & logs', '118'), ('Shared with care team', '3 summaries (their copies stay with them)')]),
        TBody('This can’t be undone. Download a copy first if you want one.', tone: TTextTone.small),
        TButton(key: const ValueKey('a:body[3]'), label: 'Download a copy first', onPressed: () => TNav.push(context, Routes.accountData), variant: TButtonVariant.secondary),
        TField(fieldKey: 'account_delete_google.type_delete_to_confirm', label: 'Type DELETE to confirm', value: 'DELETE'),
        TCard(variant: TCardVariant.mint, eyebrow: 'Confirm it’s you', title: 'Signed in with Google', text: 'When you tap Delete everything, Google asks you to confirm. Use the same Google account you signed in with.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Delete everything', onPressed: () => TNav.branch(context, 'Sign in with Google result', <String, VoidCallback>{'Success': () => TNav.submit(context, 'DELETE /v1/account/data', then: () => TNav.replace(context, Routes.accountDeleted)), 'Different account': () => TNav.toast(context, 'That’s a different Google account. Use the one you signed in with.'), 'Cancelled': () => TNav.toast(context, 'Nothing was deleted.'), 'Error': () => TNav.toast(context, 'Couldn’t reach Google. Nothing was deleted.')}, provider: 'google'), variant: TButtonVariant.danger),
      ],
    );
  }
}
