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
    return TScreen(
      header: THeader(title: 'Unplug', pill: 'On'),
      children: [
        TCard(variant: TCardVariant.mint, title: 'Unplug is on', text: '5 apps in 2 groups · pause screen after 60 min or 20 opens'),
        TCard(variant: TCardVariant.dark, eyebrow: 'Focus session', title: 'Need to focus?', text: 'Pause your chosen apps for a set time', cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: 'Start', onPressed: () => TNav.push(context, Routes.sfUnplugSession), variant: TButtonVariant.lime, small: true)),
        TListGroup(title: 'Settings', rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Apps', sub: 'Video apps · 3, Feeds · 2', onTap: () => TNav.push(context, Routes.sfUnplugAppsChosen)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Limits & pause screen', sub: '60 min · 20 opens · one breath first', onTap: () => TNav.push(context, Routes.sfUnplugLimits)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Preview the pause screen', sub: 'iPhone shield or Android overlay', onTap: () => TNav.branch(context, 'Platform', <String, VoidCallback>{'iPhone': () => TNav.push(context, Routes.sfUnplugShield), 'Android': () => TNav.push(context, Routes.sfUnplugOverlay)}, device: const TBranchRef('unplug.home.preview_platform', TAsk.platform, 'sf_unplug_home'), when: const <TAnswer, String>{TAnswer.ios: 'iPhone', TAnswer.android: 'Android'})), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Tracking check', sub: 'All checks pass', onTap: () => TNav.push(context, Routes.sfUnplugHealth))]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[3].rows[0]'), label: 'How Unplug works', sub: 'What it can and can’t see', onTap: () => TNav.push(context, Routes.sfUnplugIntro)), TListRow(key: const ValueKey('a:body[3].rows[1]'), label: 'Turn off Unplug', sub: 'Paused apps open normally again', danger: true, onTap: () => TNav.sheet(context, Routes.sfUnplugOff))]),
      ],
    );
  }
}
