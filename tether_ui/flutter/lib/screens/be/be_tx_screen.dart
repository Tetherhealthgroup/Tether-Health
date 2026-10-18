// GENERATED from spec/screens/be_tx.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Treatment support  ·  route `/p/be/treatment`  ·  flow `be`  ·  kind `screen`
/// Default state · program be · phase daily
/// 
///
/// Actions (generated from spec/screens/be_tx.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Questions → push → be_questions
///   • Call → call (555) 010-7000
///   • Today’s side-effect diary → push → be_diary
///   • Feeling worried? → push → ea_intro
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class BeTxScreen extends StatelessWidget {
  const BeTxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Beacon', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'Next appointment', title: 'Oct 22 · Oncology · 10:30 AM', cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: 'Questions', onPressed: () => TNav.push(context, Routes.beQuestions), variant: TButtonVariant.lime, small: true)),
        TCard(variant: TCardVariant.urgent, title: 'Fever of 100.4°F (38°C) or higher during chemo?', text: 'Call your oncology team now, day or night.', cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: 'Call', onPressed: () => TNav.call(context, '(555) 010-7000', label: 'Call oncology team'), variant: TButtonVariant.danger, small: true)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Today’s side-effect diary', sub: 'About 1 minute', onTap: () => TNav.push(context, Routes.beDiary)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Feeling worried?', sub: 'Tools in Ease', onTap: () => TNav.push(context, Routes.eaIntro)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings))]),
      ],
    );
  }
}
