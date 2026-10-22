// GENERATED from spec/screens/ck_list.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Due list  ·  route `/p/ck/home`  ·  flow `ck`  ·  kind `screen`
/// Default state · program ck · phase daily
/// 
///
/// Actions (generated from spec/screens/ck_list.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Find a pharmacy → external https://www.vaccines.gov
///   • I got it → push → ck_done
///   • Colorectal screening → push → ck_item
///   • Mammogram → push → ck_day
///   • Lung cancer screening → push → ck_item
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class CkListScreen extends StatelessWidget {
  const CkListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Checkup', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TTitle('3 due, 1 to ask about'),
        TCard(eyebrow: 'Due now', title: 'Flu vaccine', text: 'Every year · pharmacies offer walk-ins', children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[1].children[0].items[0]'), label: 'Find a pharmacy', onPressed: () => TNav.external(context, 'https://www.vaccines.gov'), small: true), TButton(key: const ValueKey('a:body[1].children[0].items[1]'), label: 'I got it', onPressed: () => TNav.push(context, Routes.ckDone), variant: TButtonVariant.secondary, small: true)])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Colorectal screening', sub: 'Ages 45–75 · several options', pill: 'Due', onTap: () => TNav.push(context, Routes.ckItem)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Mammogram', sub: 'Every 2 years, ages 40–74', pill: 'Due', onTap: () => TNav.push(context, Routes.ckDay)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Lung cancer screening', sub: 'Ages 50–80 with smoking history', pill: 'Ask', onTap: () => TNav.push(context, Routes.ckItem)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings, program: 'ck'))]),
      ],
    );
  }
}
