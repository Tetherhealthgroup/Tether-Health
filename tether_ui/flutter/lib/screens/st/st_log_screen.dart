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
    return TScreen(
      header: THeader(title: 'Log a reading'),
      children: [
        TField(fieldKey: 'st_log.reading', label: 'Reading', unit: 'mg/dL', hint: 'From your meter or CGM · 20–600 mg/dL', placeholder: '142', kind: TFieldKind.number),
        TChips(fieldKey: 'st_log.when', options: ['Fasting', 'Before meal', '2 h after meal', 'Bedtime', 'Other'], selected: ['2 h after meal'], multi: false, label: 'When?'),
        TChips(fieldKey: 'st_log.how_do_you_feel', options: ['Fine', 'Shaky', 'Sweaty', 'Tired', 'Thirsty'], selected: ['Fine'], label: 'How do you feel?'),
        TField(fieldKey: 'st_log.note_optional', label: 'Note (optional)', hint: 'Never shared unless you choose', placeholder: 'Pasta lunch'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save reading', onPressed: () => TNav.submit(context, 'POST /v1/program-data/st/readings', then: () => TNav.branch(context, 'Reading vs. your range', <String, VoidCallback>{'In or above range': () => TNav.toast(context, 'Saved', then: () => TNav.replace(context, Routes.stHome)), 'Below your low': () => TNav.replace(context, Routes.stLow), 'Invalid (outside 20–600)': () => TNav.toast(context, 'Check your meter reading')}, decide: 'st.glucose')), arrow: true),
      ],
    );
  }
}
