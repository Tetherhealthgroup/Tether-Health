// GENERATED from spec/screens/be_survivor.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Survivorship  ·  route `/p/be/survivorship`  ·  flow `be`  ·  kind `screen`
/// Default state · program be · phase milestone
/// 
///
/// Actions (generated from spec/screens/be_survivor.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Open Ease → push → ea_intro
///   • Program settings → push → program_settings
///   • Save check-in → POST /v1/program-data/be/survivorship then toast “Saved”
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class BeSurvivorScreen extends StatelessWidget {
  const BeSurvivorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Beacon', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TTitle(s.beSurvivorBodyN0Text),
        TSegmented(fieldKey: 'be_survivor.value', options: ['Hard', 'Mixed', 'Good'], labels: [s.beSurvivorBodyN1OptionsN0, s.beSurvivorBodyN1OptionsN1, s.beSurvivorBodyN1OptionsN2], selected: 'Mixed'),
        TCard(title: s.beSurvivorBodyN2Title, text: s.beSurvivorBodyN2Text, cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: s.beSurvivorBodyN2CtaN0Label, onPressed: () => TNav.push(context, Routes.eaIntro), variant: TButtonVariant.secondary, small: true)),
        TBoundValues(keys: const ['be.next_follow_up'], builder: (context, v) => TKeyValue(rows: [(s.beSurvivorBodyN3RowsN0N0, v.text('be.next_follow_up', s.beSurvivorBodyN3RowsN0N1))])),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: s.beSurvivorBodyN4RowsN0Label, onTap: () => TNav.push(context, Routes.programSettings, program: 'be'))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.beSurvivorFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/be/survivorship', screenId: 'be_survivor', then: () => TNav.toast(context, s.beSurvivorFooterN0ActionThenValue)), arrow: true),
      ],
    );
  }
}
