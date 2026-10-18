// GENERATED from spec/screens/sf_unplug_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Unplug intro  ·  route `/p/sf/unplug`  ·  flow `unplug`  ·  kind `screen`
/// Default state · program sf · phase plan
/// Copy needs clinical/legal review. Shown before anything is switched on, so nobody later reads a number that does not exist. Pause 60 stays an intent check; Unplug is the optional lock.
///
/// Actions (generated from spec/screens/sf_unplug_intro.json):
///   • Back → back
///   • Set up Unplug → branch: Platform → iPhone: push → sf_unplug_auth | Android: push → sf_unplug_auth_android
///   • Not now → back
/// API: —
class SfUnplugIntroScreen extends StatelessWidget {
  const SfUnplugIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Unplug', pill: 'Optional'),
      children: [
        TProgramTag(program: 'sf', extra: 'Unplug'),
        TTitle('Pause the apps you choose, when you choose.', size: TTitleSize.l),
        TBody('Unplug is optional. It adds a pause screen to apps you pick, after limits you set. Pause 60 stays the same: a moment to check in, never a lock.', tone: TTextTone.muted),
        TKeyValue(rows: [('Can', 'Pause apps you pick, after your limits'), ('Can’t', 'See what you do inside any app'), ('On iPhone', 'Apple doesn’t share app names or minutes with Tether'), ('Stays', 'On this phone. Your app list never reaches Tether'), ('Never paused', 'Tether, phone calls and emergency calls')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Set up Unplug', onPressed: () => TNav.branch(context, 'Platform', <String, VoidCallback>{'iPhone': () => TNav.push(context, Routes.sfUnplugAuth), 'Android': () => TNav.push(context, Routes.sfUnplugAuthAndroid)}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Not now', onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
