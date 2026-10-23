// GENERATED from spec/screens/account_notifications.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Notifications  ·  route `/account/notifications`  ·  flow `account`  ·  kind `screen`
/// Default state · phase account
/// 
///
/// Actions (generated from spec/screens/account_notifications.json):
///   • Back → back
///   • BreatheFree → toast “Reminder time saved”
///   • ScrollFree → toast “Reminder time saved”
///   • Save → PATCH /v1/notifications/preferences then toast “Saved” then back
/// API: —
class AccountNotificationsScreen extends StatelessWidget {
  const AccountNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.accountNotificationsHeaderTitle),
      children: [
        TCard(children: [TToggleRow(fieldKey: 'account_notifications.check_ins_and_plan_reminders', label: s.accountNotificationsBodyN0ChildrenN0Label, sub: s.accountNotificationsBodyN0ChildrenN0Sub, value: true, bind: 'notifications.check_ins_and_plan_reminders'), TToggleRow(fieldKey: 'account_notifications.show_sensitive_details', label: s.accountNotificationsBodyN0ChildrenN1Label, sub: s.accountNotificationsBodyN0ChildrenN1Sub, bind: 'notifications.show_sensitive_details'), TToggleRow(fieldKey: 'account_notifications.quiet_hours', label: s.accountNotificationsBodyN0ChildrenN2Label, sub: s.accountNotificationsBodyN0ChildrenN2Sub, value: true, bind: 'notifications.quiet_hours')]),
        TBoundValues(keys: const ['notifications.bf.summary', 'notifications.sf.summary'], builder: (context, v) => TListGroup(title: s.accountNotificationsBodyN1Title, rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'BreatheFree', sub: v.text('notifications.bf.summary', s.accountNotificationsBodyN1RowsN0Sub), lead: TLead.program('bf'), onTap: () => TNav.toast(context, s.accountNotificationsBodyN1RowsN0ActionValue)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'ScrollFree', sub: v.text('notifications.sf.summary', s.accountNotificationsBodyN1RowsN1Sub), lead: TLead.program('sf'), onTap: () => TNav.toast(context, s.accountNotificationsBodyN1RowsN1ActionValue))])),
        TCard(eyebrow: s.accountNotificationsBodyN2Eyebrow, title: 'Tether Health', text: s.accountNotificationsBodyN2Text),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.accountNotificationsFooterN0Label, onPressed: () => TNav.submit(context, 'PATCH /v1/notifications/preferences', screenId: 'account_notifications', then: () => TNav.toast(context, s.accountNotificationsFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
