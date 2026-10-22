// GENERATED from spec/screens/sf_unplug_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Unplug  ·  route `/p/sf/unplug/home`  ·  flow `unplug`  ·  kind `screen`
/// Default state · program sf · phase daily
/// Copy needs clinical/legal review. Reached from ScrollFree home (state "Unplug on") and ScrollFree settings. Everything shown is read from this phone.
///
/// Actions (generated from spec/screens/sf_unplug_home.json):
///   • Back → back
///   • Start → push → sf_unplug_session
///   • Apps → push → sf_unplug_apps_chosen
///   • Limits & pause screen → push → sf_unplug_limits
///   • Preview the pause screen → branch: Platform → iPhone: push → sf_unplug_shield | Android: push → sf_unplug_overlay
///   • Tracking check → push → sf_unplug_health
///   • How Unplug works → push → sf_unplug_intro
///   • Turn off Unplug → sheet → sf_unplug_off
/// API: —
class SfUnplugHomeScreen extends StatelessWidget {
  const SfUnplugHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Unplug', pill: s.sfUnplugHomeHeaderPill),
      children: [
        TCard(variant: TCardVariant.mint, title: s.sfUnplugHomeBodyN0Title, text: s.sfUnplugHomeBodyN0Text),
        TCard(variant: TCardVariant.dark, eyebrow: s.sfUnplugHomeBodyN1Eyebrow, title: s.sfUnplugHomeBodyN1Title, text: s.sfUnplugHomeBodyN1Text, cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: s.sfUnplugHomeBodyN1CtaN0Label, onPressed: () => TNav.push(context, Routes.sfUnplugSession), variant: TButtonVariant.lime, small: true)),
        TListGroup(title: s.sfUnplugHomeBodyN2Title, rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.sfUnplugHomeBodyN2RowsN0Label, sub: s.sfUnplugHomeBodyN2RowsN0Sub, onTap: () => TNav.push(context, Routes.sfUnplugAppsChosen)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.sfUnplugHomeBodyN2RowsN1Label, sub: s.sfUnplugHomeBodyN2RowsN1Sub, onTap: () => TNav.push(context, Routes.sfUnplugLimits)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.sfUnplugHomeBodyN2RowsN2Label, sub: s.sfUnplugHomeBodyN2RowsN2Sub, onTap: () => TNav.branch(context, 'Platform', <String, VoidCallback>{'iPhone': () => TNav.push(context, Routes.sfUnplugShield), 'Android': () => TNav.push(context, Routes.sfUnplugOverlay)}, device: const TBranchRef('unplug.home.preview_platform', TAsk.platform, 'sf_unplug_home'), when: const <TAnswer, String>{TAnswer.ios: 'iPhone', TAnswer.android: 'Android'})), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: s.sfUnplugHomeBodyN2RowsN3Label, sub: s.sfUnplugHomeBodyN2RowsN3Sub, onTap: () => TNav.push(context, Routes.sfUnplugHealth))]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: s.sfUnplugHomeBodyN3RowsN0Label, sub: s.sfUnplugHomeBodyN3RowsN0Sub, onTap: () => TNav.push(context, Routes.sfUnplugIntro)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: s.sfUnplugHomeBodyN3RowsN1Label, sub: s.sfUnplugHomeBodyN3RowsN1Sub, danger: true, onTap: () => TNav.sheet(context, Routes.sfUnplugOff))]),
      ],
    );
  }
}
