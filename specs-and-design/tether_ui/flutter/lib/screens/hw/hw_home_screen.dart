// GENERATED from spec/screens/hw_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Heartwise home  ·  route `/p/hw/home`  ·  flow `hw`  ·  kind `screen`
/// Default state · program hw · phase daily
/// 
///
/// Actions (generated from spec/screens/hw_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Log blood pressure → push → hw_log
///   • Trends → push → hw_trends
///   • Cholesterol panel → push → hw_lipids
///   • Visit summary → push → hw_summary
///   • From your health record → push → records_item
///   • My targets → push → hw_targets
///   • Program settings → push → program_settings
///   • Call 911 → call 911
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class HwHomeScreen extends StatelessWidget {
  const HwHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Heartwise', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TBoundValues(keys: const ['hw.last_reading_time', 'hw.last_bp', 'hw.last_bp_caption'], builder: (context, v) => TCard(variant: TCardVariant.dark, eyebrow: v.text('hw.last_reading_time', s.hwHomeBodyN0Eyebrow), children: [TBigNumber(value: v.text('hw.last_bp', '128/82'), unit: 'mmHg', caption: v.text('hw.last_bp_caption', s.hwHomeBodyN0ChildrenN0Caption))])),
        TButton(key: const ValueKey('a:body[1]'), label: s.hwHomeBodyN1Label, onPressed: () => TNav.push(context, Routes.hwLog), arrow: true),
        TBoundValues(keys: const ['hw.avg_30d_summary', 'hw.lipids_summary', 'hw.records_summary', 'hw.targets_summary'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.hwHomeBodyN2RowsN0Label, sub: v.text('hw.avg_30d_summary', s.hwHomeBodyN2RowsN0Sub), onTap: () => TNav.push(context, Routes.hwTrends)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.hwHomeBodyN2RowsN1Label, sub: v.text('hw.lipids_summary', s.hwHomeBodyN2RowsN1Sub), onTap: () => TNav.push(context, Routes.hwLipids)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.hwHomeBodyN2RowsN2Label, sub: s.hwHomeBodyN2RowsN2Sub, onTap: () => TNav.push(context, Routes.hwSummary)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: s.hwHomeBodyN2RowsN3Label, sub: v.text('hw.records_summary', s.hwHomeBodyN2RowsN3Sub), onTap: () => TNav.push(context, Routes.recordsItem)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: s.hwHomeBodyN2RowsN4Label, sub: v.text('hw.targets_summary', s.hwHomeBodyN2RowsN4Sub), onTap: () => TNav.push(context, Routes.hwTargets)), TListRow(key: const ValueKey('a:body[2].rows[5]'), label: s.hwHomeBodyN2RowsN5Label, sub: s.hwHomeBodyN2RowsN5Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'hw'))])),
        TEmergencyCard(text: s.hwHomeBodyN3Text, actions: [TButton(key: const ValueKey('a:body[3].actions[0]'), label: s.hwHomeBodyN3ActionsN0Label, onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger, small: true)]),
      ],
    );
  }
}
