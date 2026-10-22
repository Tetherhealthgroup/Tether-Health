// GENERATED from spec/screens/ca_zone.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Zone check  ·  route `/p/ca/zone`  ·  flow `ca`  ·  kind `screen`
/// Default state · program ca · phase daily
/// "Can’t speak in full sentences" routes to red regardless of peak flow.
///
/// Actions (generated from spec/screens/ca_zone.json):
///   • Back → back
///   • Save and see my steps → POST /v1/program-data/ca/zone-checks then decide ca.zone: Computed zone → Green: toast “Green zone · follow your daily routine” then replace → ca_home | Yellow: replace → ca_yellow | Red: replace → ca_red | Invalid peak flow: toast “Check your peak flow: 50–900 L/min”
/// API: —
class CaZoneScreen extends StatelessWidget {
  const CaZoneScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.caZoneHeaderTitle, pill: s.caZoneHeaderPill),
      children: [
        TTitle(s.caZoneBodyN0Text),
        TField(fieldKey: 'ca_zone.peak_flow', label: s.caZoneBodyN1Label, unit: 'L/min', hint: s.caZoneBodyN1Hint, placeholder: '310', kind: TFieldKind.number),
        TChips(fieldKey: 'ca_zone.symptoms', options: ['Coughing', 'Wheezing', 'Short of breath', 'Chest tightness', 'Woke at night', 'Can’t speak in full sentences'], labels: [s.caZoneBodyN2OptionsN0, s.caZoneBodyN2OptionsN1, s.caZoneBodyN2OptionsN2, s.caZoneBodyN2OptionsN3, s.caZoneBodyN2OptionsN4, s.caZoneBodyN2OptionsN5], selected: ['Wheezing'], label: s.caZoneBodyN2Label),
        TEyebrow(s.caZoneBodyN3Text),
        TZoneSelector(selected: 'yellow', rule: 'ca.zone'),
        TBody(s.caZoneBodyN5Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.caZoneFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/ca/zone-checks', screenId: 'ca_zone', then: () => TNav.branch(context, 'Computed zone', <String, VoidCallback>{'Green': () => TNav.toast(context, s.caZoneFooterN0ActionThenCasesN0ActionValue, then: () => TNav.replace(context, Routes.caHome)), 'Yellow': () => TNav.replace(context, Routes.caYellow), 'Red': () => TNav.replace(context, Routes.caRed), 'Invalid peak flow': () => TNav.toast(context, s.caZoneFooterN0ActionThenCasesN3ActionValue)}, decide: 'ca.zone'), safety: TSafetyRoutes('ca.zone', <String, VoidCallback>{'Red': () => TNav.replace(context, Routes.caRed)})), arrow: true),
      ],
    );
  }
}
