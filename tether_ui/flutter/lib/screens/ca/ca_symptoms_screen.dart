// GENERATED from spec/screens/ca_symptoms.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Symptom log  ·  route `/p/ca/symptoms`  ·  flow `ca`  ·  kind `screen`
/// Default state · program ca · phase daily
/// 
///
/// Actions (generated from spec/screens/ca_symptoms.json):
///   • Back → back
///   • Save → POST /v1/program-data/ca/symptoms then toast “Saved” then back
/// API: —
class CaSymptomsScreen extends StatelessWidget {
  const CaSymptomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.caSymptomsHeaderTitle),
      children: [
        TTitle(s.caSymptomsBodyN0Text),
        TChips(fieldKey: 'ca_symptoms.value', options: ['Coughing', 'Wheezing', 'Short of breath', 'Chest tightness', 'Woke at night'], labels: [s.caSymptomsBodyN1OptionsN0, s.caSymptomsBodyN1OptionsN1, s.caSymptomsBodyN1OptionsN2, s.caSymptomsBodyN1OptionsN3, s.caSymptomsBodyN1OptionsN4], selected: ['Wheezing', 'Woke at night']),
        TSegmented(fieldKey: 'ca_symptoms.how_bad', options: ['Mild', 'Moderate', 'Severe'], labels: [s.caSymptomsBodyN2OptionsN0, s.caSymptomsBodyN2OptionsN1, s.caSymptomsBodyN2OptionsN2], selected: 'Mild', label: s.caSymptomsBodyN2Label),
        TChips(fieldKey: 'ca_symptoms.possible_trigger', options: ['Cold air', 'Smoke', 'Pollen', 'Exercise', 'Not sure'], labels: [s.caSymptomsBodyN3OptionsN0, s.caSymptomsBodyN3OptionsN1, s.caSymptomsBodyN3OptionsN2, s.caSymptomsBodyN3OptionsN3, s.caSymptomsBodyN3OptionsN4], selected: ['Cold air'], label: s.caSymptomsBodyN3Label),
        TField(fieldKey: 'ca_symptoms.note_optional', label: s.caSymptomsBodyN4Label, placeholder: s.caSymptomsBodyN4Placeholder, kind: TFieldKind.multiline),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.caSymptomsFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/ca/symptoms', screenId: 'ca_symptoms', then: () => TNav.toast(context, s.caSymptomsFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
