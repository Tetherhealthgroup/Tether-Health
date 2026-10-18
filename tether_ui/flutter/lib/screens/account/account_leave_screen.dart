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
    return TSheet(
      children: [
        TTitle('Leave BreatheFree?'),
        TBody('Reminders stop right away. Your other programs are not affected.', tone: TTextTone.muted),
        TRadioList(fieldKey: 'account_leave.value', items: [TRadioItem('Keep my data for 30 days', sub: 'Rejoin anytime and pick up where you left off', badge: 'Default'), TRadioItem('Delete BreatheFree data now', sub: '63 check-ins, 14 rescues, 1 plan')], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Leave BreatheFree', onPressed: () => TNav.submit(context, 'DELETE /v1/enrolments/:id', then: () => TNav.toast(context, 'You left BreatheFree', then: () => TNav.reset(context, Routes.plans))), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
