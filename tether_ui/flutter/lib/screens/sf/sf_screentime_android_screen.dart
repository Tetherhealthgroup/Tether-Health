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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfScreentimeAndroidHeaderTitle, pill: s.sfScreentimeAndroidHeaderPill),
      children: [
        TIllustration(glyph: '◷'),
        TTitle(s.sfScreentimeAndroidBodyN1Text, center: true),
        TBody(s.sfScreentimeAndroidBodyN2Text, tone: TTextTone.muted, center: true),
        TKeyValue(rows: [(s.sfScreentimeAndroidBodyN3RowsN0N0, s.sfScreentimeAndroidBodyN3RowsN0N1), (s.sfScreentimeAndroidBodyN3RowsN1N0, s.sfScreentimeAndroidBodyN3RowsN1N1), (s.sfScreentimeAndroidBodyN3RowsN2N0, s.sfScreentimeAndroidBodyN3RowsN2N1)]),
        TChecklist(items: [TCheckItem(s.sfScreentimeAndroidBodyN4ItemsN0Label, value: 'Tap Open settings'), TCheckItem(s.sfScreentimeAndroidBodyN4ItemsN1Label, value: 'Find Tether Health'), TCheckItem(s.sfScreentimeAndroidBodyN4ItemsN2Label, value: 'Turn on “Permit usage access”')], label: s.sfScreentimeAndroidBodyN4Label),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfScreentimeAndroidFooterN0Label, onPressed: () => TNav.branch(context, 'Android usage access (checked on return)', <String, VoidCallback>{'Allowed': () => TNav.toast(context, s.sfScreentimeAndroidFooterN0ActionCasesN0ActionValue, then: () => TNav.back(context)), 'Not allowed': () => TNav.replace(context, Routes.sfScreentimeAndroidDenied)}, device: const TBranchRef('sf.screentime.android_usage_access', TAsk.usageAccessSettings, 'sf_screentime_android'), when: const <TAnswer, String>{TAnswer.granted: 'Allowed', TAnswer.denied: 'Not allowed'}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfScreentimeAndroidFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
