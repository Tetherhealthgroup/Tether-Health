// GENERATED from spec/screens/account_deleted.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Deletion receipt  ·  route `/account/deleted`  ·  flow `account`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/account_deleted.json):
///   • Done → reset → welcome
/// API: —
class AccountDeletedScreen extends StatelessWidget {
  const AccountDeletedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.accountDeletedHeaderTitle, left: THeaderLeft.none),
      children: [
        TIllustration(glyph: '✓'),
        TTitle(s.accountDeletedBodyN1Text, size: TTitleSize.l, center: true),
        TKeyValue(rows: [(s.accountDeletedBodyN2RowsN0N0, s.accountDeletedBodyN2RowsN0N1), (s.accountDeletedBodyN2RowsN1N0, s.accountDeletedBodyN2RowsN1N1), (s.accountDeletedBodyN2RowsN2N0, s.accountDeletedBodyN2RowsN2N1)]),
        TBody(s.accountDeletedBodyN3Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.accountDeletedFooterN0Label, onPressed: () => TNav.reset(context, Routes.welcome), arrow: true),
      ],
    );
  }
}
