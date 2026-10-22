// GENERATED from spec/screens/auth_merge.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Guest plan merge  ·  route `/auth/merge`  ·  flow `auth`  ·  kind `sheet`
/// Default state · phase account
/// Create-only import: a concurrent cloud plan returns 409 and both plans are kept.
///
/// Actions (generated from spec/screens/auth_merge.json):
///   • Continue → POST /v1/quit-plan/guest-import then reset → today
/// API: POST /v1/quit-plan/guest-import
class AuthMergeScreen extends StatelessWidget {
  const AuthMergeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TEyebrow(s.authMergeBodyN0Text),
        TTitle(s.authMergeBodyN1Text),
        TListGroup(rows: [TListRow(label: s.authMergeBodyN2RowsN0Label, sub: s.authMergeBodyN2RowsN0Sub, lead: TLead.program('bf'))]),
        TBody(s.authMergeBodyN3Text, tone: TTextTone.small),
        TRadioList(fieldKey: 'auth_merge.value', items: [TRadioItem(s.authMergeBodyN4ItemsN0Label, value: 'Keep both, choose later', sub: s.authMergeBodyN4ItemsN0Sub, badge: s.authMergeBodyN4ItemsN0Badge), TRadioItem(s.authMergeBodyN4ItemsN1Label, value: 'Use this phone’s plan'), TRadioItem(s.authMergeBodyN4ItemsN2Label, value: 'Use the account’s plan')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.authMergeFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/quit-plan/guest-import', screenId: 'auth_merge', then: () => TNav.reset(context, Routes.today)), arrow: true),
      ],
    );
  }
}
