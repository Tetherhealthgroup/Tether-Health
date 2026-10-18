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
    return TScreen(
      header: THeader(title: 'Screen Time', pill: 'Optional'),
      children: [
        TIllustration(glyph: '◷'),
        TTitle('See your Screen Time here, if you want.', center: true),
        TBody('Apple’s Screen Time shows your daily totals by category inside Tether. Tether can’t read, store or share those minutes.', tone: TTextTone.muted, center: true),
        TKeyValue(rows: [('Shows', 'Minutes per category, on this phone'), ('Never reads', 'Content, messages, contacts'), ('Turn off', 'Anytime in Account')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Allow access', onPressed: () => TNav.branch(context, 'iOS Screen Time permission', <String, VoidCallback>{'Allowed': () => TNav.toast(context, 'Screen Time connected', then: () => TNav.back(context)), 'Not allowed': () => TNav.replace(context, Routes.sfScreentimeDenied)}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Not now', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
