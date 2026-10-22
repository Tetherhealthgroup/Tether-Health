// GENERATED from spec/screens/ck_day.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Screening day  ·  route `/p/ck/day`  ·  flow `ck`  ·  kind `screen`
/// Default state · program ck · phase milestone
/// 
///
/// Actions (generated from spec/screens/ck_day.json):
///   • Back → back
///   • 2-min breathing → push → rescue_active
///   • Add to calendar → toast “Added to your calendar”
///   • Mark as done → push → ck_done
/// API: —
class CkDayScreen extends StatelessWidget {
  const CkDayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.ckDayHeaderTitle, pill: s.ckDayHeaderPill),
      children: [
        TTitle(s.ckDayBodyN0Text),
        TCard(children: [TChecklist(items: [TCheckItem(s.ckDayBodyN1ChildrenN0ItemsN0Label, value: 'Skip deodorant or powder', done: true), TCheckItem(s.ckDayBodyN1ChildrenN0ItemsN1Label, value: 'Wear a two-piece outfit'), TCheckItem(s.ckDayBodyN1ChildrenN0ItemsN2Label, value: 'Bring ID and insurance card')])]),
        TCard(variant: TCardVariant.mint, title: s.ckDayBodyN2Title, text: s.ckDayBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.ckDayBodyN2CtaN0Label, onPressed: () => TNav.push(context, Routes.rescueActive), small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.ckDayFooterN0Label, onPressed: () => TNav.toast(context, s.ckDayFooterN0ActionValue), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.ckDayFooterN1Label, onPressed: () => TNav.push(context, Routes.ckDone), variant: TButtonVariant.secondary),
      ],
    );
  }
}
