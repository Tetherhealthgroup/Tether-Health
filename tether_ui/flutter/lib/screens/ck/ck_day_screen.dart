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
    return TScreen(
      header: THeader(title: 'Screening day', pill: 'Tomorrow'),
      children: [
        TTitle('Mammogram tomorrow at 9:30 AM'),
        TCard(children: [TChecklist(items: [TCheckItem('Skip deodorant or powder', done: true), TCheckItem('Wear a two-piece outfit'), TCheckItem('Bring ID and insurance card')])]),
        TCard(variant: TCardVariant.mint, title: 'Nervous?', text: 'It’s common. The scan takes about 20 minutes.', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: '2-min breathing', onPressed: () => TNav.push(context, Routes.rescueActive), small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Add to calendar', onPressed: () => TNav.toast(context, 'Added to your calendar'), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Mark as done', onPressed: () => TNav.push(context, Routes.ckDone), variant: TButtonVariant.secondary),
      ],
    );
  }
}
