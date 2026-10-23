// GENERATED from spec/screens/st_home.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Steady home  ·  route `/p/st/home`  ·  flow `st`  ·  kind `screen`
/// Default state · program st · phase daily
/// 
///
/// Actions (generated from spec/screens/st_home.json):
///   • Back → back
///   • Avatar · Account → push → account
///   • Log a reading → push → st_log
///   • Meal energy reset → push → st_reset
///   • Patterns → push → st_patterns
///   • A1C history → push → st_a1c
///   • My range & low plan → push → st_range
///   • Program settings → push → program_settings
///   • Tab · Today → tab → today
///   • Tab · Progress → tab → progress
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: —
class StHomeScreen extends StatelessWidget {
  const StHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Steady', avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'plans',
      children: [
        TBoundValues(keys: const ['st.last_reading_context', 'st.last_glucose', 'st.last_glucose_caption'], builder: (context, v) => TCard(variant: TCardVariant.dark, eyebrow: v.text('st.last_reading_context', s.stHomeBodyN0Eyebrow), children: [TBigNumber(value: v.text('st.last_glucose', '142'), unit: 'mg/dL', caption: v.text('st.last_glucose_caption', s.stHomeBodyN0ChildrenN0Caption))])),
        TButton(key: const ValueKey('a:body[1]'), label: s.stHomeBodyN1Label, onPressed: () => TNav.push(context, Routes.stLog), arrow: true),
        TBoundValues(keys: const ['st.in_range_summary', 'st.a1c_latest'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.stHomeBodyN2RowsN0Label, sub: s.stHomeBodyN2RowsN0Sub, onTap: () => TNav.push(context, Routes.stReset)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.stHomeBodyN2RowsN1Label, sub: v.text('st.in_range_summary', s.stHomeBodyN2RowsN1Sub), onTap: () => TNav.push(context, Routes.stPatterns)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.stHomeBodyN2RowsN2Label, sub: v.text('st.a1c_latest', s.stHomeBodyN2RowsN2Sub), onTap: () => TNav.push(context, Routes.stA1c)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: s.stHomeBodyN2RowsN3Label, onTap: () => TNav.push(context, Routes.stRange)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: s.stHomeBodyN2RowsN4Label, sub: s.stHomeBodyN2RowsN4Sub, onTap: () => TNav.push(context, Routes.programSettings, program: 'st'))])),
        TCard(variant: TCardVariant.mint, text: s.stHomeBodyN3Text),
      ],
    );
  }
}
