// GENERATED from spec/screens/bf_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// BreatheFree home  ·  route `/p/bf/home`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase daily
/// Pre-quit state. Quit-day and Explore states are variants.
///
/// Actions (generated from spec/screens/bf_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Rescue → sheet → rescue_pick
///   • Daily check-in → sheet → checkin
///   • Medication center → push → bf_meds
///   • Progress → push → bf_progress
///   • Edit my plan → push → bf_review
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class BfHomeScreen extends StatelessWidget {
  const BfHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'BreatheFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: s.bfHomeBodyN0Eyebrow, children: [TBigNumber(value: s.bfHomeBodyN0ChildrenN0Value, caption: s.bfHomeBodyN0ChildrenN0Caption)]),
        TCard(variant: TCardVariant.coral, title: s.bfHomeBodyN1Title, text: s.bfHomeBodyN1Text, cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: s.bfHomeBodyN1CtaN0Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TCard(eyebrow: s.bfHomeBodyN2Eyebrow, children: [TChecklist(items: [TCheckItem(s.bfHomeBodyN2ChildrenN0ItemsN0Label, value: 'Stock gum, water or healthy snacks', sub: s.bfHomeBodyN2ChildrenN0ItemsN0Sub)])]),
        TCard(variant: TCardVariant.mint, eyebrow: s.bfHomeBodyN3Eyebrow, children: [TQuote(s.bfHomeBodyN3ChildrenN0Text)]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: s.bfHomeBodyN4RowsN0Label, sub: s.bfHomeBodyN4RowsN0Sub, onTap: () => TNav.sheet(context, Routes.checkin)), TListRow(key: const ValueKey('a:body[4].rows[1]'), label: s.bfHomeBodyN4RowsN1Label, sub: s.bfHomeBodyN4RowsN1Sub, onTap: () => TNav.push(context, Routes.bfMeds)), TListRow(key: const ValueKey('a:body[4].rows[2]'), label: s.bfHomeBodyN4RowsN2Label, sub: s.bfHomeBodyN4RowsN2Sub, onTap: () => TNav.push(context, Routes.bfProgress)), TListRow(key: const ValueKey('a:body[4].rows[3]'), label: s.bfHomeBodyN4RowsN3Label, onTap: () => TNav.push(context, Routes.bfReview)), TListRow(key: const ValueKey('a:body[4].rows[4]'), label: s.bfHomeBodyN4RowsN4Label, sub: s.bfHomeBodyN4RowsN4Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'bf'))]),
      ],
    );
  }
}
