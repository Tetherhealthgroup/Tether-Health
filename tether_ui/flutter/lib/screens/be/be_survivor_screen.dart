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
    return TScreen(
      header: THeader(title: 'Beacon', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TTitle('How have the last 3 months been?'),
        TSegmented(fieldKey: 'be_survivor.value', options: ['Hard', 'Mixed', 'Good'], selected: 'Mixed'),
        TCard(title: 'Worried about it coming back?', text: 'Very common. Ease has tools for this, and your team can help.', cta: TButton(key: const ValueKey('a:body[2].cta[0]'), label: 'Open Ease', onPressed: () => TNav.push(context, Routes.eaIntro), variant: TButtonVariant.secondary, small: true)),
        TKeyValue(rows: [('Next follow-up', 'Jan 14, 2027')]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[4].rows[0]'), label: 'Program settings', onTap: () => TNav.push(context, Routes.programSettings))]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save check-in', onPressed: () => TNav.submit(context, 'POST /v1/program-data/be/survivorship', screenId: 'be_survivor', then: () => TNav.toast(context, 'Saved')), arrow: true),
      ],
    );
  }
}
