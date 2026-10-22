// GENERATED from spec/screens/progress_error.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Progress · error  ·  route `/progress?state=error`  ·  flow `tabs`  ·  kind `screen`
/// State: error of progress · phase resources
/// 
///
/// Actions (generated from spec/screens/progress_error.json):
///   • Avatar · Account → push → account
///   • Try again → replace → progress
///   • Tab · Today → tab → today
///   • Tab · Plans → tab → plans
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class ProgressErrorScreen extends StatelessWidget {
  const ProgressErrorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.progressErrorHeaderTitle, left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'progress',
      children: [
        TIllustration(glyph: '!', tone: TTone.error),
        TTitle(s.progressErrorBodyN1Text, center: true),
        TBody(s.progressErrorBodyN2Text, tone: TTextTone.muted, center: true),
        TButton(key: const ValueKey('a:body[3]'), label: s.progressErrorBodyN3Label, onPressed: () => TNav.replace(context, Routes.progress), arrow: true),
        TBody(s.progressErrorBodyN4Text, tone: TTextTone.small, center: true),
      ],
    );
  }
}
