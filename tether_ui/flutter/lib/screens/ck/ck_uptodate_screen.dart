// GENERATED from spec/screens/ck_uptodate.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Up to date  ·  route `/p/ck/home?state=empty`  ·  flow `ck`  ·  kind `screen`
/// State: empty of ck_list · program ck · phase daily
/// 
///
/// Actions (generated from spec/screens/ck_uptodate.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • See full schedule → replace → ck_list
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class CkUptodateScreen extends StatelessWidget {
  const CkUptodateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Checkup', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TIllustration(glyph: '✓'),
        TTitle('You’re up to date', size: TTitleSize.l, center: true),
        TBody('Next: flu vaccine in Sep 2027. We’ll remind you a month before.', tone: TTextTone.muted, center: true),
        TButton(key: const ValueKey('a:body[3]'), label: 'See full schedule', onPressed: () => TNav.replace(context, Routes.ckList), variant: TButtonVariant.secondary),
      ],
    );
  }
}
