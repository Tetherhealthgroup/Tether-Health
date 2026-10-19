// GENERATED from spec/screens/ck_done.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Mark done  ·  route `/p/ck/done`  ·  flow `ck`  ·  kind `screen`
/// Default state · program ck · phase milestone
/// 
///
/// Actions (generated from spec/screens/ck_done.json):
///   • Back → back
///   • Save → POST /v1/program-data/ck/done then toast “Saved · next due Sep 2027” then replace → ck_list
/// API: —
class CkDoneScreen extends StatelessWidget {
  const CkDoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Mark as done'),
      children: [
        TField(fieldKey: 'ck_done.what', label: 'What', placeholder: 'Flu vaccine', kind: TFieldKind.select),
        TField(fieldKey: 'ck_done.date', label: 'Date', placeholder: 'Oct 12, 2026', kind: TFieldKind.date),
        TField(fieldKey: 'ck_done.where_optional', label: 'Where (optional)', placeholder: 'Main St Pharmacy'),
        TChecklist(items: [TCheckItem('Remind me next year', done: true)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'POST /v1/program-data/ck/done', screenId: 'ck_done', then: () => TNav.toast(context, 'Saved · next due Sep 2027', then: () => TNav.replace(context, Routes.ckList))), arrow: true),
      ],
    );
  }
}
