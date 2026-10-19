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
    return TSheet(
      children: [
        TEyebrow('You’re signed in'),
        TTitle('Upload the plan on this phone?'),
        TListGroup(rows: [TListRow(label: 'BreatheFree plan · this phone', sub: 'Quit date Aug 28 · 3 reasons', lead: TLead.program('bf'))]),
        TBody('Your account already has a BreatheFree plan from Aug 12.', tone: TTextTone.small),
        TRadioList(fieldKey: 'auth_merge.value', items: [TRadioItem('Keep both, choose later', sub: 'Nothing is overwritten', badge: 'Safest'), TRadioItem('Use this phone’s plan'), TRadioItem('Use the account’s plan')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Continue', onPressed: () => TNav.submit(context, 'POST /v1/quit-plan/guest-import', screenId: 'auth_merge', then: () => TNav.reset(context, Routes.today)), arrow: true),
      ],
    );
  }
}
