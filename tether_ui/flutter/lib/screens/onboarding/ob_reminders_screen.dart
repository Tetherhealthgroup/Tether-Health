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
    return TScreen(
      header: THeader(title: 'Reminders'),
      children: [
        TIllustration(glyph: '◔'),
        TTitle('Quiet, private reminders', size: TTitleSize.l, center: true),
        TBody('At most 2 a day, only for your focus programs.', center: true),
        TCard(eyebrow: 'Lock screen preview', text: 'Program names and health details stay hidden unless you turn them on.', children: [TCard(variant: TCardVariant.flat, title: 'Tether Health', text: 'You have a Tether reminder.')]),
        TToggleRow(fieldKey: 'ob_reminders.quiet_hours', label: 'Quiet hours', sub: '9:00 PM – 7:00 AM · safety alerts still come through', value: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Turn on reminders', onPressed: () => TNav.branch(context, 'System permission prompt', <String, VoidCallback>{'Allowed': () => TNav.push(context, Routes.obAccount), 'Not allowed': () => TNav.push(context, Routes.obRemindersDenied)}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Not now', onPressed: () => TNav.push(context, Routes.obAccount), variant: TButtonVariant.secondary),
      ],
    );
  }
}
