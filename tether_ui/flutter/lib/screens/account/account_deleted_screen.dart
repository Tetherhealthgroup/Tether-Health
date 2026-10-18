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
    return TScreen(
      header: THeader(title: 'Deleted', left: THeaderLeft.none),
      children: [
        TIllustration(glyph: '✓'),
        TTitle('Your data has been deleted.', size: TTitleSize.l, center: true),
        TKeyValue(rows: [('Receipt', 'DEL-7F3A-21C9'), ('Completed', 'Oct 17, 2026 · 9:41 AM'), ('Signed out on', 'this phone')]),
        TBody('Keep this receipt if you contact support. Backups are purged within 30 days.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Done', onPressed: () => TNav.reset(context, Routes.welcome), arrow: true),
      ],
    );
  }
}
