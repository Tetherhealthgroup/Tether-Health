// GENERATED from spec/screens/st_a1c.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// A1C  ·  route `/p/st/a1c`  ·  flow `st`  ·  kind `screen`
/// Default state · program st · phase milestone
/// 
///
/// Actions (generated from spec/screens/st_a1c.json):
///   • Back → back
///   • Save → POST /v1/program-data/st/a1c then toast “Saved” then back
/// API: —
class StA1cScreen extends StatelessWidget {
  const StA1cScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'A1C lab', pill: 'Lab day'),
      children: [
        TTitle('Add your A1C'),
        TField(fieldKey: 'st_a1c.a1c', label: 'A1C', unit: '%', placeholder: '7.4', kind: TFieldKind.number),
        TField(fieldKey: 'st_a1c.lab_date', label: 'Lab date', placeholder: 'Oct 1, 2026', kind: TFieldKind.date),
        TKeyValue(rows: [('Previous', '7.9% · Jul 2'), ('Change', '−0.5 points')]),
        TBody('Your clinician sets your A1C goal. Steady shows history only.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save', onPressed: () => TNav.submit(context, 'POST /v1/program-data/st/a1c', screenId: 'st_a1c', then: () => TNav.toast(context, 'Saved', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
