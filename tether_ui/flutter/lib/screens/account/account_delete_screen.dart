// GENERATED from spec/screens/account_delete.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Delete account  ·  route `/account/delete`  ·  flow `account`  ·  kind `screen`
/// Default state · phase account
/// Encrypted deletion-intent tombstone is written before the request (develop branch design).
///
/// Actions (generated from spec/screens/account_delete.json):
///   • Back → back
///   • Download a copy first → push → account_data
///   • Delete everything → DELETE /v1/account/data then replace → account_deleted
/// API: DELETE /v1/account/data
class AccountDeleteScreen extends StatelessWidget {
  const AccountDeleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Delete account'),
      children: [
        TTitle('Delete your account and all data?'),
        TKeyValue(rows: [('Programs', '4'), ('Check-ins', '63'), ('Readings & logs', '118'), ('Shared with care team', '3 summaries (their copies stay with them)')]),
        TBody('This can’t be undone. Download a copy first if you want one.', tone: TTextTone.small),
        TButton(key: const ValueKey('a:body[3]'), label: 'Download a copy first', onPressed: () => TNav.push(context, Routes.accountData), variant: TButtonVariant.secondary),
        TField(fieldKey: 'account_delete.type_delete_to_confirm', label: 'Type DELETE to confirm', placeholder: 'DELETE'),
        TField(fieldKey: 'account_delete.password', label: 'Password', hint: 'We ask again to protect your account.', placeholder: '••••••••••••', kind: TFieldKind.password),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Delete everything', onPressed: () => TNav.submit(context, 'DELETE /v1/account/data', then: () => TNav.replace(context, Routes.accountDeleted)), variant: TButtonVariant.danger),
      ],
    );
  }
}
