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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.accountDeleteHeaderTitle),
      children: [
        TTitle(s.accountDeleteBodyN0Text),
        TBoundValues(keys: const ['account.data.programs', 'account.data.check_ins', 'account.data.readings', 'account.data.shared_summaries'], builder: (context, v) => TKeyValue(rows: [(s.accountDeleteBodyN1RowsN0N0, v.text('account.data.programs', '4')), (s.accountDeleteBodyN1RowsN1N0, v.text('account.data.check_ins', '63')), (s.accountDeleteBodyN1RowsN2N0, v.text('account.data.readings', '118')), (s.accountDeleteBodyN1RowsN3N0, v.text('account.data.shared_summaries', s.accountDeleteBodyN1RowsN3N1))])),
        TBody(s.accountDeleteBodyN2Text, tone: TTextTone.small),
        TButton(key: const ValueKey('a:body[3]'), label: s.accountDeleteBodyN3Label, onPressed: () => TNav.push(context, Routes.accountData), variant: TButtonVariant.secondary),
        TField(fieldKey: 'account_delete.type_delete_to_confirm', label: s.accountDeleteBodyN4Label, placeholder: s.accountDeleteBodyN4Placeholder),
        TField(fieldKey: 'account_delete.password', label: s.accountDeleteBodyN5Label, hint: s.accountDeleteBodyN5Hint, placeholder: '••••••••••••', kind: TFieldKind.password),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.accountDeleteFooterN0Label, onPressed: () => TNav.submit(context, 'DELETE /v1/account/data', screenId: 'account_delete', then: () => TNav.replace(context, Routes.accountDeleted)), variant: TButtonVariant.danger),
      ],
    );
  }
}
