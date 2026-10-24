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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.stLowHeaderTitle, left: THeaderLeft.close),
      children: [
        TBoundValues(keys: const ['st.low_banner'], builder: (context, v) => TBanner(kind: TBannerKind.urgent, text: v.text('st.low_banner', s.stLowBodyN0Text))),
        TCard(variant: TCardVariant.warn, eyebrow: s.stLowBodyN1Eyebrow, children: [TChecklist(items: [TCheckItem(s.stLowBodyN1ChildrenN0ItemsN0Label, value: 'Take 15 g of fast sugar', sub: s.stLowBodyN1ChildrenN0ItemsN0Sub, done: true), TCheckItem(s.stLowBodyN1ChildrenN0ItemsN1Label, value: 'Re-check in 15 minutes'), TCheckItem(s.stLowBodyN1ChildrenN0ItemsN2Label, value: 'Repeat if still below 70')])]),
        TTimer(value: '14:52', label: s.stLowBodyN2Label),
        TCard(variant: TCardVariant.urgent, title: s.stLowBodyN3Title, text: s.stLowBodyN3Text, children: [TButton(key: const ValueKey('a:body[3].children[0]'), label: s.stLowBodyN3ChildrenN0Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.stLowFooterN0Label, onPressed: () => TNav.replace(context, Routes.stLog), arrow: true),
      ],
    );
  }
}
