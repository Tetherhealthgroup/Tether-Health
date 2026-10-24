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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Beacon', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TBoundValues(keys: const ['be.next_appointment'], builder: (context, v) => TCard(variant: TCardVariant.dark, eyebrow: s.beTxBodyN0Eyebrow, title: v.text('be.next_appointment', s.beTxBodyN0Title), cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: s.beTxBodyN0CtaN0Label, onPressed: () => TNav.push(context, Routes.beQuestions), variant: TButtonVariant.lime, small: true))),
        TCard(variant: TCardVariant.urgent, title: s.beTxBodyN1Title, text: s.beTxBodyN1Text, cta: TButton(key: const ValueKey('a:body[1].cta[0]'), label: s.beTxBodyN1CtaN0Label, onPressed: () => TNav.call(context, '(555) 010-7000', label: 'Call oncology team'), variant: TButtonVariant.danger, small: true)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.beTxBodyN2RowsN0Label, sub: s.beTxBodyN2RowsN0Sub, onTap: () => TNav.push(context, Routes.beDiary)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.beTxBodyN2RowsN1Label, sub: s.beTxBodyN2RowsN1Sub, onTap: () => TNav.push(context, Routes.eaIntro)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.beTxBodyN2RowsN2Label, sub: s.beTxBodyN2RowsN2Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'be'))]),
      ],
    );
  }
}
