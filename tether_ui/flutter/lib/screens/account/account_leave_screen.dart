// GENERATED from spec/screens/account_leave.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Leave a program  ·  route `/account/programs/leave`  ·  flow `account`  ·  kind `sheet`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/account_leave.json):
///   • Leave BreatheFree → DELETE /v1/enrolments/:id then toast “You left BreatheFree” then reset → plans
///   • Cancel → close
/// API: —
class AccountLeaveScreen extends StatelessWidget {
  const AccountLeaveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TTitle(s.accountLeaveBodyN0Text),
        TBody(s.accountLeaveBodyN1Text, tone: TTextTone.muted),
        TRadioList(fieldKey: 'account_leave.value', items: [TRadioItem(s.accountLeaveBodyN2ItemsN0Label, value: 'Keep my data', sub: s.accountLeaveBodyN2ItemsN0Sub, badge: s.accountLeaveBodyN2ItemsN0Badge), TRadioItem(s.accountLeaveBodyN2ItemsN1Label, value: 'Delete BreatheFree data now', sub: s.accountLeaveBodyN2ItemsN1Sub)], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.accountLeaveFooterN0Label, onPressed: () => TNav.submit(context, 'DELETE /v1/enrolments/:id', screenId: 'account_leave', then: () => TNav.toast(context, s.accountLeaveFooterN0ActionThenValue, then: () => TNav.reset(context, Routes.plans))), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:footer[1]'), label: s.accountLeaveFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
