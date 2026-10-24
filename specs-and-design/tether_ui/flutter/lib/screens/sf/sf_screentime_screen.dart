// GENERATED from spec/screens/sf_screentime.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Connect Screen Time  ·  route `/p/sf/screen-time`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase plan
/// 
///
/// Actions (generated from spec/screens/sf_screentime.json):
///   • Back → back
///   • Allow access → branch: iOS Screen Time permission → Allowed: toast “Screen Time connected” then back | Not allowed: replace → sf_screentime_denied
///   • Not now → back
/// API: —
class SfScreentimeScreen extends StatelessWidget {
  const SfScreentimeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfScreentimeHeaderTitle, pill: s.sfScreentimeHeaderPill),
      children: [
        TIllustration(glyph: '◷'),
        TTitle(s.sfScreentimeBodyN1Text, center: true),
        TBody(s.sfScreentimeBodyN2Text, tone: TTextTone.muted, center: true),
        TKeyValue(rows: [(s.sfScreentimeBodyN3RowsN0N0, s.sfScreentimeBodyN3RowsN0N1), (s.sfScreentimeBodyN3RowsN1N0, s.sfScreentimeBodyN3RowsN1N1), (s.sfScreentimeBodyN3RowsN2N0, s.sfScreentimeBodyN3RowsN2N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfScreentimeFooterN0Label, onPressed: () => TNav.branch(context, 'iOS Screen Time permission', <String, VoidCallback>{'Allowed': () => TNav.toast(context, s.sfScreentimeFooterN0ActionCasesN0ActionValue, then: () => TNav.back(context)), 'Not allowed': () => TNav.replace(context, Routes.sfScreentimeDenied)}, device: const TBranchRef('sf.screentime.ios_request', TAsk.screenTimeRequest, 'sf_screentime'), when: const <TAnswer, String>{TAnswer.granted: 'Allowed', TAnswer.denied: 'Not allowed', TAnswer.unavailable: 'Not allowed'}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfScreentimeFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
