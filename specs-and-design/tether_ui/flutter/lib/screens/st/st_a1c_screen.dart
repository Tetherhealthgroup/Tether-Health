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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.stA1cHeaderTitle, pill: s.stA1cHeaderPill),
      children: [
        TTitle(s.stA1cBodyN0Text),
        TField(fieldKey: 'st_a1c.a1c', label: s.stA1cBodyN1Label, unit: '%', placeholder: '7.4', kind: TFieldKind.number),
        TField(fieldKey: 'st_a1c.lab_date', label: s.stA1cBodyN2Label, placeholder: s.stA1cBodyN2Placeholder, kind: TFieldKind.date),
        TBoundValues(keys: const ['st.a1c_previous', 'st.a1c_change'], builder: (context, v) => TKeyValue(rows: [(s.stA1cBodyN3RowsN0N0, v.text('st.a1c_previous', s.stA1cBodyN3RowsN0N1)), (s.stA1cBodyN3RowsN1N0, v.text('st.a1c_change', s.stA1cBodyN3RowsN1N1))])),
        TBody(s.stA1cBodyN4Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.stA1cFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/program-data/st/a1c', screenId: 'st_a1c', then: () => TNav.toast(context, s.stA1cFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
