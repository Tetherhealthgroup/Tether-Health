// GENERATED from spec/screens/account_data.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Your data  ·  route `/account/data`  ·  flow `account`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/account_data.json):
///   • Back → back
///   • Download everything → POST /v1/account/export then toast “We’re preparing your file. We’ll notify you when it’s ready.”
///   • Export a care summary → push → hw_summary
///   • Delete account and all data → push → account_delete
/// API: —
class AccountDataScreen extends StatelessWidget {
  const AccountDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your data'),
      children: [
        TListGroup(title: 'Export', rows: [TListRow(key: const ValueKey('a:body[0].rows[0]'), label: 'Download everything', sub: 'Every program · PDF + JSON', onTap: () => TNav.submit(context, 'POST /v1/account/export', screenId: 'account_data', then: () => TNav.toast(context, 'We’re preparing your file. We’ll notify you when it’s ready.'))), TListRow(key: const ValueKey('a:body[0].rows[1]'), label: 'Export a care summary', sub: 'Choose dates and preview every detail', onTap: () => TNav.push(context, Routes.hwSummary))]),
        TListGroup(title: 'Delete', rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'Delete account and all data', sub: 'Permanent · requires confirmation', danger: true, onTap: () => TNav.push(context, Routes.accountDelete))]),
      ],
    );
  }
}
