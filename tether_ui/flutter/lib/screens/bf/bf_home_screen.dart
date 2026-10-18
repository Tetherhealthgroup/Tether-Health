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
    return TScreen(
      header: THeader(title: 'BreatheFree', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'Your quit day', children: [TBigNumber(value: '7 days', caption: 'Friday, August 28 · Pacific Time')]),
        TCard(variant: TCardVariant.coral, title: 'Craving now?', text: 'One tap · works offline', cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: 'Rescue', onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
        TCard(eyebrow: 'Today’s step', children: [TChecklist(items: [TCheckItem('Stock gum, water or healthy snacks', sub: 'About 3 minutes')])]),
        TCard(variant: TCardVariant.mint, eyebrow: 'Your top reason', children: [TQuote('Protect my family.')]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: 'Daily check-in', sub: 'About 60 seconds', onTap: () => TNav.sheet(context, Routes.checkin)), TListRow(key: const ValueKey('a:body[4].rows[1]'), label: 'Medication center', sub: 'Nicotine patch · recorded plan', onTap: () => TNav.push(context, Routes.bfMeds)), TListRow(key: const ValueKey('a:body[4].rows[2]'), label: 'Progress', sub: 'Saved \$42.70 so far', onTap: () => TNav.push(context, Routes.bfProgress)), TListRow(key: const ValueKey('a:body[4].rows[3]'), label: 'Edit my plan', onTap: () => TNav.push(context, Routes.bfReview)), TListRow(key: const ValueKey('a:body[4].rows[4]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings))]),
      ],
    );
  }
}
