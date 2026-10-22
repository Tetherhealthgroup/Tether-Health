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
    return TScreen(
      header: THeader(title: 'Notifications'),
      children: [
        TCard(children: [TToggleRow(fieldKey: 'account_notifications.check_ins_and_plan_reminders', label: 'Check-ins and plan reminders', sub: 'At most 2 a day', value: true, bind: 'notifications.check_ins_and_plan_reminders'), TToggleRow(fieldKey: 'account_notifications.show_sensitive_details', label: 'Show sensitive details', sub: 'Off: program names and health data hidden', bind: 'notifications.show_sensitive_details'), TToggleRow(fieldKey: 'account_notifications.quiet_hours', label: 'Quiet hours', sub: '9:00 PM – 7:00 AM · safety alerts still come through', value: true, bind: 'notifications.quiet_hours')]),
        TListGroup(title: 'Per program', rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'BreatheFree', sub: '8:00 AM check-in', lead: TLead.program('bf'), onTap: () => TNav.toast(context, 'Reminder time saved')), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'ScrollFree', sub: '9:30 PM wind-down', lead: TLead.program('sf'), onTap: () => TNav.toast(context, 'Reminder time saved'))]),
        TCard(eyebrow: 'Lock screen preview', title: 'Tether Health', text: 'You have a Tether reminder.'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'PATCH /v1/notifications/preferences', screenId: 'account_notifications', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
