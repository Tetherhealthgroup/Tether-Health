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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Renew', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TCard(variant: TCardVariant.dark, eyebrow: s.reHomeBodyN0Eyebrow, children: [TBigNumber(value: '58', unit: 'mL/min', caption: s.reHomeBodyN0ChildrenN0Caption)]),
        TCard(eyebrow: s.reHomeBodyN1Eyebrow, children: [TChecklist(items: [TCheckItem(s.reHomeBodyN1ChildrenN0ItemsN0Label, value: 'Medicine reminder · 8:00 AM', sub: s.reHomeBodyN1ChildrenN0ItemsN0Sub, done: true), TCheckItem(s.reHomeBodyN1ChildrenN0ItemsN1Label, value: 'Water reminder', sub: s.reHomeBodyN1ChildrenN0ItemsN1Sub)])]),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.reHomeBodyN2RowsN0Label, onTap: () => TNav.push(context, Routes.reLabs)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.reHomeBodyN2RowsN1Label, sub: s.reHomeBodyN2RowsN1Sub, onTap: () => TNav.push(context, Routes.reHistory)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.reHomeBodyN2RowsN2Label, onTap: () => TNav.push(context, Routes.reSymptoms)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: s.reHomeBodyN2RowsN3Label, sub: s.reHomeBodyN2RowsN3Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 're'))]),
        TCard(variant: TCardVariant.mint, title: s.reHomeBodyN3Title, text: s.reHomeBodyN3Text),
      ],
    );
  }
}
