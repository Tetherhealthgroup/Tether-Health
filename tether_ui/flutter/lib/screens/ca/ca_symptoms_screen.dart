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
    return TScreen(
      header: THeader(title: 'Log symptoms'),
      children: [
        TTitle('What are you noticing?'),
        TChips(fieldKey: 'ca_symptoms.value', options: ['Coughing', 'Wheezing', 'Short of breath', 'Chest tightness', 'Woke at night'], selected: ['Wheezing', 'Woke at night']),
        TSegmented(fieldKey: 'ca_symptoms.how_bad', options: ['Mild', 'Moderate', 'Severe'], selected: 'Mild', label: 'How bad?'),
        TChips(fieldKey: 'ca_symptoms.possible_trigger', options: ['Cold air', 'Smoke', 'Pollen', 'Exercise', 'Not sure'], selected: ['Cold air'], label: 'Possible trigger'),
        TField(fieldKey: 'ca_symptoms.note_optional', label: 'Note (optional)', placeholder: 'Anything else to tell your clinician', kind: TFieldKind.multiline),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'POST /v1/program-data/ca/symptoms', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
