// GENERATED from spec/screens/st_range.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Range & low plan  ·  route `/p/st/plan/range`  ·  flow `st`  ·  kind `screen`
/// Default state · program st · phase plan
/// 
///
/// Actions (generated from spec/screens/st_range.json):
///   • Back → back
///   • Import from my health record → push → records_add
///   • Save range → PUT /v1/program-data/st/range then replace → st_home (onboarding: ob_setup)
/// API: —
class StRangeScreen extends StatelessWidget {
  const StRangeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Your range', pill: '2 of 2'),
      children: [
        TSteps(n: 2, total: 2),
        TTitle('Enter the range your clinician gave you.'),
        TSegmented(fieldKey: 'st_range.value', options: ['mg/dL', 'mmol/L'], selected: 'mg/dL', bind: 'st.range.unit', bindClass: TBindClass.plan),
        TFieldRow(children: [TField(fieldKey: 'st_range.before_meals_from', label: 'Before meals from', unit: 'mg/dL', placeholder: '80', kind: TFieldKind.number), TField(fieldKey: 'st_range.to', label: 'to', unit: 'mg/dL', placeholder: '130', kind: TFieldKind.number)]),
        TField(fieldKey: 'st_range.2_h_after_meals_below', label: '2 h after meals below', unit: 'mg/dL', placeholder: '180', kind: TFieldKind.number),
        TCard(eyebrow: 'Your low plan', children: [TField(fieldKey: 'st_range.low', label: 'Low below', unit: 'mg/dL', placeholder: '70', kind: TFieldKind.number), TField(fieldKey: 'st_range.my_low_steps', label: 'My low steps', placeholder: '15 g fast sugar, re-check in 15 min', kind: TFieldKind.multiline)]),
        TLink(key: const ValueKey('a:body[6]'), label: 'Import from my health record', onTap: () => TNav.push(context, Routes.recordsAdd)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save range', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/st/range', screenId: 'st_range', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.stHome))), arrow: true),
      ],
    );
  }
}
