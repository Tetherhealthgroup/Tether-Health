// GENERATED from spec/screens/sf_screentime_android.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Connect usage access (Android)  ·  route `/p/sf/screen-time?state=android`  ·  flow `sf`  ·  kind `screen`
/// State: android of sf_screentime · program sf · phase plan
/// Copy needs clinical/legal review. Android has no permission prompt for usage access; the person turns it on in Settings and the app checks again on return.
///
/// Actions (generated from spec/screens/sf_screentime_android.json):
///   • Back → back
///   • Open settings → branch: Android usage access (checked on return) → Allowed: toast “Usage access on” then back | Not allowed: replace → sf_screentime_android_denied
///   • Not now → back
/// API: —
class SfScreentimeAndroidScreen extends StatelessWidget {
  const SfScreentimeAndroidScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Screen Time', pill: 'Optional'),
      children: [
        TIllustration(glyph: '◷'),
        TTitle('See real totals, if you want.', center: true),
        TBody('Tether reads daily totals by category only. Never apps’ content, messages or contacts.', tone: TTextTone.muted, center: true),
        TKeyValue(rows: [('Reads', 'Minutes per category'), ('Never reads', 'Content, messages, contacts'), ('Turn off', 'Anytime in Account')]),
        TChecklist(items: [TCheckItem('Tap Open settings'), TCheckItem('Find Tether Health'), TCheckItem('Turn on “Permit usage access”')], label: 'Android asks in Settings'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Open settings', onPressed: () => TNav.branch(context, 'Android usage access (checked on return)', <String, VoidCallback>{'Allowed': () => TNav.toast(context, 'Usage access on', then: () => TNav.back(context)), 'Not allowed': () => TNav.replace(context, Routes.sfScreentimeAndroidDenied)}, device: const TBranchRef('sf.screentime.android_usage_access', TAsk.usageAccessSettings, 'sf_screentime_android'), when: const <TAnswer, String>{TAnswer.granted: 'Allowed', TAnswer.denied: 'Not allowed'}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Not now', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
