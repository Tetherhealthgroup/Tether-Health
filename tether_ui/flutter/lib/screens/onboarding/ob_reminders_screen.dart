// GENERATED from spec/screens/ob_reminders.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Reminder prime  ·  route `/onboarding/reminders`  ·  flow `onboarding`  ·  kind `screen`
/// Default state · phase onboarding
/// Shown before the OS prompt so the system dialog is expected.
///
/// Actions (generated from spec/screens/ob_reminders.json):
///   • Back → back
///   • Turn on reminders → branch: System permission prompt → Allowed: push → ob_account | Not allowed: push → ob_reminders_denied
///   • Not now → push → ob_account
/// API: —
class ObRemindersScreen extends StatelessWidget {
  const ObRemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.obRemindersHeaderTitle),
      children: [
        TIllustration(glyph: '◔'),
        TTitle(s.obRemindersBodyN1Text, size: TTitleSize.l, center: true),
        TBody(s.obRemindersBodyN2Text, center: true),
        TCard(eyebrow: s.obRemindersBodyN3Eyebrow, text: s.obRemindersBodyN3Text, children: [TCard(variant: TCardVariant.flat, title: 'Tether Health', text: s.obRemindersBodyN3ChildrenN0Text)]),
        TToggleRow(fieldKey: 'ob_reminders.quiet_hours', label: s.obRemindersBodyN4Label, sub: s.obRemindersBodyN4Sub, value: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.obRemindersFooterN0Label, onPressed: () => TNav.branch(context, 'System permission prompt', <String, VoidCallback>{'Allowed': () => TNav.push(context, Routes.obAccount), 'Not allowed': () => TNav.push(context, Routes.obRemindersDenied)}, device: const TBranchRef('onboarding.reminders.notifications_request', TAsk.notificationsRequest, 'ob_reminders'), when: const <TAnswer, String>{TAnswer.granted: 'Allowed', TAnswer.denied: 'Not allowed', TAnswer.unavailable: 'Not allowed'}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.obRemindersFooterN1Label, onPressed: () => TNav.push(context, Routes.obAccount), variant: TButtonVariant.secondary),
      ],
    );
  }
}
