// GENERATED from spec/screens/sf_unplug_health.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Tracking check  ·  route `/p/sf/unplug/health`  ·  flow `unplug`  ·  kind `screen`
/// Default state · program sf · phase daily
/// Copy needs clinical/legal review.
///
/// Actions (generated from spec/screens/sf_unplug_health.json):
///   • Back → back
///   • Done → back
/// API: —
class SfUnplugHealthScreen extends StatelessWidget {
  const SfUnplugHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Tracking check'),
      children: [
        TBanner(kind: TBannerKind.success, text: 'Unplug is working. All 4 checks pass.'),
        TChecklist(items: [TCheckItem('Screen Time permission', sub: 'Allowed', done: true), TCheckItem('Daily schedule', sub: 'Running', done: true), TCheckItem('Settings shared with the pause screen', sub: 'Ready', done: true), TCheckItem('Notifications', sub: 'On · lets the pause screen open Tether for support', done: true)], label: 'iPhone checks'),
        TBody('If a check fails, Unplug stops counting and pausing. We’ll tell you instead of letting you think it’s still on.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Done', onPressed: () => TNav.back(context), arrow: true),
      ],
    );
  }
}
