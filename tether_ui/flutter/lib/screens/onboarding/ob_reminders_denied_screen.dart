// GENERATED from spec/screens/ob_reminders_denied.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Reminders denied  ·  route `/onboarding/reminders?state=denied`  ·  flow `onboarding`  ·  kind `screen`
/// State: permission denied of ob_reminders · phase onboarding
/// 
///
/// Actions (generated from spec/screens/ob_reminders_denied.json):
///   • Back → back
///   • Open phone settings → os_settings
///   • Continue without reminders → push → ob_account
/// API: —
class ObRemindersDeniedScreen extends StatelessWidget {
  const ObRemindersDeniedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Reminders'),
      children: [
        TBanner(kind: TBannerKind.info, text: 'Notifications are off in your phone settings.'),
        TTitle('You can still use everything.'),
        TBody('Today shows your steps when you open the app. To get reminders, allow notifications for Tether in Settings.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Open phone settings', onPressed: () => TNav.osSettings(context), variant: TButtonVariant.secondary),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Continue without reminders', onPressed: () => TNav.push(context, Routes.obAccount), arrow: true),
      ],
    );
  }
}
