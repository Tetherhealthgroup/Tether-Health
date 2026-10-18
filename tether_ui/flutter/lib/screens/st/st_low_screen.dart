// GENERATED from spec/screens/st_low.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Low reading  ·  route `/p/st/low`  ·  flow `st`  ·  kind `fullscreen`
/// Default state · program st · phase rescue
/// Timer survives app close and fires during quiet hours.
///
/// Actions (generated from spec/screens/st_low.json):
///   • Close → close
///   • Call 911 → call 911
///   • Re-check now → replace → st_log
/// API: —
class StLowScreen extends StatelessWidget {
  const StLowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Low reading', left: THeaderLeft.close),
      children: [
        TBanner(kind: TBannerKind.urgent, text: '62 mg/dL is below your low of 70.'),
        TCard(variant: TCardVariant.warn, eyebrow: 'Your low plan', children: [TChecklist(items: [TCheckItem('Take 15 g of fast sugar', sub: '4 glucose tablets or ½ cup juice', done: true), TCheckItem('Re-check in 15 minutes'), TCheckItem('Repeat if still below 70')])]),
        TTimer(value: '14:52', label: 'until re-check'),
        TCard(variant: TCardVariant.urgent, title: 'Confused, can’t swallow or passing out?', text: 'Someone should call 911 now.', children: [TButton(key: const ValueKey('a:body[3].children[0]'), label: 'Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Re-check now', onPressed: () => TNav.replace(context, Routes.stLog), arrow: true),
      ],
    );
  }
}
