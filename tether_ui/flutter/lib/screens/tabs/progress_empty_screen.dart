// GENERATED from spec/screens/progress_empty.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Progress · empty  ·  route `/progress?state=empty`  ·  flow `tabs`  ·  kind `screen`
/// State: empty of progress · phase resources
/// 
///
/// Actions (generated from spec/screens/progress_empty.json):
///   • Avatar · Account → push → account
///   • Do a check-in → sheet → checkin
///   • Tab · Today → tab → today
///   • Tab · Plans → tab → plans
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class ProgressEmptyScreen extends StatelessWidget {
  const ProgressEmptyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.progressEmptyHeaderTitle, left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'progress',
      children: [
        TIllustration(glyph: '0'),
        TTitle(s.progressEmptyBodyN1Text, center: true),
        TBody(s.progressEmptyBodyN2Text, tone: TTextTone.muted, center: true),
        TButton(key: const ValueKey('a:body[3]'), label: s.progressEmptyBodyN3Label, onPressed: () => TNav.sheet(context, Routes.checkin), arrow: true),
      ],
    );
  }
}
