// GENERATED from spec/screens/st_log.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Log reading  ·  route `/p/st/log`  ·  flow `st`  ·  kind `screen`
/// Default state · program st · phase daily
/// 
///
/// Actions (generated from spec/screens/st_log.json):
///   • Back → back
///   • Save reading → POST /v1/program-data/st/readings then decide st.glucose: Reading vs. your range → In or above range: toast “Saved” then replace → st_home | Below your low: replace → st_low | Invalid (outside 20–600): toast “Check your meter reading”
/// API: —
class StLogScreen extends StatelessWidget {
  const StLogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.stLogHeaderTitle),
      children: [
        TField(fieldKey: 'st_log.reading', label: s.stLogBodyN0Label, unit: 'mg/dL', hint: s.stLogBodyN0Hint, placeholder: '142', kind: TFieldKind.number),
        TChips(fieldKey: 'st_log.when', options: ['Fasting', 'Before meal', '2 h after meal', 'Bedtime', 'Other'], labels: [s.stLogBodyN1OptionsN0, s.stLogBodyN1OptionsN1, s.stLogBodyN1OptionsN2, s.stLogBodyN1OptionsN3, s.stLogBodyN1OptionsN4], selected: ['2 h after meal'], multi: false, label: s.stLogBodyN1Label),
        TChips(fieldKey: 'st_log.how_do_you_feel', options: ['Fine', 'Shaky', 'Sweaty', 'Tired', 'Thirsty'], labels: [s.stLogBodyN2OptionsN0, s.stLogBodyN2OptionsN1, s.stLogBodyN2OptionsN2, s.stLogBodyN2OptionsN3, s.stLogBodyN2OptionsN4], selected: ['Fine'], label: s.stLogBodyN2Label),
        TField(fieldKey: 'st_log.note_optional', label: s.stLogBodyN3Label, hint: s.stLogBodyN3Hint, placeholder: s.stLogBodyN3Placeholder),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.stLogFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/st/readings', screenId: 'st_log', then: () => TNav.branch(context, 'Reading vs. your range', <String, VoidCallback>{'In or above range': () => TNav.toast(context, s.stLogFooterN0ActionThenCasesN0ActionValue, then: () => TNav.replace(context, Routes.stHome)), 'Below your low': () => TNav.replace(context, Routes.stLow), 'Invalid (outside 20–600)': () => TNav.toast(context, s.stLogFooterN0ActionThenCasesN2ActionValue)}, decide: 'st.glucose'), safety: TSafetyRoutes('st.glucose', <String, VoidCallback>{'Below your low': () => TNav.replace(context, Routes.stLow)})), arrow: true),
      ],
    );
  }
}
