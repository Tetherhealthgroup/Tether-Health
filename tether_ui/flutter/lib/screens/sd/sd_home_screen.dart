// GENERATED from spec/screens/sd_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Stride home  ·  route `/p/sd/home`  ·  flow `sd`  ·  kind `screen`
/// Default state · program sd · phase daily
/// 
///
/// Actions (generated from spec/screens/sd_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Start → push → sd_session
///   • I fell → push → sd_fell
///   • Home safety checklist → push → sd_safety
///   • Caregiver access → push → sd_caregiver
///   • Movement plan → push → sd_plan
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class SdHomeScreen extends StatelessWidget {
  const SdHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Stride', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: s.sdHomeBodyN0Eyebrow, title: s.sdHomeBodyN0Title, cta: TButton(key: const ValueKey('a:body[0].cta[0]'), label: s.sdHomeBodyN0CtaN0Label, onPressed: () => TNav.push(context, Routes.sdSession), variant: TButtonVariant.lime, small: true)),
        TCard(key: const ValueKey('a:body[1]'), variant: TCardVariant.urgent, title: s.sdHomeBodyN1Title, text: s.sdHomeBodyN1Text, onTap: () => TNav.push(context, Routes.sdFell)),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.sdHomeBodyN2RowsN0Label, sub: s.sdHomeBodyN2RowsN0Sub, onTap: () => TNav.push(context, Routes.sdSafety)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.sdHomeBodyN2RowsN1Label, sub: s.sdHomeBodyN2RowsN1Sub, onTap: () => TNav.push(context, Routes.sdCaregiver)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.sdHomeBodyN2RowsN2Label, sub: s.sdHomeBodyN2RowsN2Sub, onTap: () => TNav.push(context, Routes.sdPlan)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: s.sdHomeBodyN2RowsN3Label, sub: s.sdHomeBodyN2RowsN3Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'sd'))]),
        TStatGrid(stats: [TStat(label: s.sdHomeBodyN3ItemsN0Label, value: s.sdHomeBodyN3ItemsN0Value, sub: s.sdHomeBodyN3ItemsN0Sub), TStat(label: s.sdHomeBodyN3ItemsN1Label, value: '0', sub: s.sdHomeBodyN3ItemsN1Sub)]),
      ],
    );
  }
}
