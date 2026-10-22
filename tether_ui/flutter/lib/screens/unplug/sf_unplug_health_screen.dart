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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugHealthHeaderTitle),
      children: [
        TBanner(kind: TBannerKind.success, text: s.sfUnplugHealthBodyN0Text),
        TChecklist(items: [TCheckItem(s.sfUnplugHealthBodyN1ItemsN0Label, value: 'Screen Time permission', sub: s.sfUnplugHealthBodyN1ItemsN0Sub, done: true), TCheckItem(s.sfUnplugHealthBodyN1ItemsN1Label, value: 'Daily schedule', sub: s.sfUnplugHealthBodyN1ItemsN1Sub, done: true), TCheckItem(s.sfUnplugHealthBodyN1ItemsN2Label, value: 'Settings shared with the pause screen', sub: s.sfUnplugHealthBodyN1ItemsN2Sub, done: true), TCheckItem(s.sfUnplugHealthBodyN1ItemsN3Label, value: 'Notifications', sub: s.sfUnplugHealthBodyN1ItemsN3Sub, done: true)], label: s.sfUnplugHealthBodyN1Label),
        TBody(s.sfUnplugHealthBodyN2Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugHealthFooterN0Label, onPressed: () => TNav.back(context), arrow: true),
      ],
    );
  }
}
