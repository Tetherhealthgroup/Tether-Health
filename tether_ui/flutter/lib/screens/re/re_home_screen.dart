// GENERATED from spec/screens/re_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Renew home  ·  route `/p/re/home`  ·  flow `re`  ·  kind `screen`
/// Default state · program re · phase daily
/// 
///
/// Actions (generated from spec/screens/re_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Add lab results → push → re_labs
///   • Lab history → push → re_history
///   • Check symptoms → push → re_symptoms
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class ReHomeScreen extends StatelessWidget {
  const ReHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Renew', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: 'Latest eGFR · Oct 3', children: [TBigNumber(value: '58', unit: 'mL/min', caption: 'Next check Apr 2027 · from your clinician')]),
        TCard(eyebrow: 'Today', children: [TChecklist(items: [TCheckItem('Medicine reminder · 8:00 AM', sub: 'As entered from your clinician', done: true), TCheckItem('Water reminder', sub: 'Only if your clinician hasn’t limited fluids')])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Add lab results', onTap: () => TNav.push(context, Routes.reLabs)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Lab history', sub: '2 years', onTap: () => TNav.push(context, Routes.reHistory)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Check symptoms', onTap: () => TNav.push(context, Routes.reSymptoms)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Program settings', sub: 'Status, sharing, export, leave', onTap: () => TNav.push(context, Routes.programSettings))]),
        TCard(variant: TCardVariant.mint, title: 'Over-the-counter pain relief?', text: 'Some (like ibuprofen) can affect kidneys. Ask your pharmacist.'),
      ],
    );
  }
}
