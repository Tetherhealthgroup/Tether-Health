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
    return TScreen(
      header: THeader(title: 'Progress', left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'progress',
      children: [
        TIllustration(glyph: '!', tone: TTone.error),
        TTitle('Something went wrong on our side', center: true),
        TBody('Your data is safe on this phone. Try again in a moment.', tone: TTextTone.muted, center: true),
        TButton(key: const ValueKey('a:body[3]'), label: 'Try again', onPressed: () => TNav.replace(context, Routes.progress), arrow: true),
        TBody('Reference 5xx-2F91 · reports never include health data', tone: TTextTone.small, center: true),
      ],
    );
  }
}
