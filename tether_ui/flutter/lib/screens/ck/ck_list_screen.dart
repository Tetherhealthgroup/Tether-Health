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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Checkup', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TTitle(s.ckListBodyN0Text),
        TCard(eyebrow: s.ckListBodyN1Eyebrow, title: s.ckListBodyN1Title, text: s.ckListBodyN1Text, children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[1].children[0].items[0]'), label: s.ckListBodyN1ChildrenN0ItemsN0Label, onPressed: () => TNav.external(context, 'https://www.vaccines.gov'), small: true), TButton(key: const ValueKey('a:body[1].children[0].items[1]'), label: s.ckListBodyN1ChildrenN0ItemsN1Label, onPressed: () => TNav.push(context, Routes.ckDone), variant: TButtonVariant.secondary, small: true)])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.ckListBodyN2RowsN0Label, sub: s.ckListBodyN2RowsN0Sub, pill: s.ckListBodyN2RowsN0Pill, onTap: () => TNav.push(context, Routes.ckItem)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.ckListBodyN2RowsN1Label, sub: s.ckListBodyN2RowsN1Sub, pill: s.ckListBodyN2RowsN1Pill, onTap: () => TNav.push(context, Routes.ckDay)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.ckListBodyN2RowsN2Label, sub: s.ckListBodyN2RowsN2Sub, pill: s.ckListBodyN2RowsN2Pill, onTap: () => TNav.push(context, Routes.ckItem)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: s.ckListBodyN2RowsN3Label, sub: s.ckListBodyN2RowsN3Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'ck'))]),
      ],
    );
  }
}
