// GENERATED from spec/screens/bf_meds_edit.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Edit recorded plan  ·  route `/p/bf/meds/edit`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase resources
/// 
///
/// Actions (generated from spec/screens/bf_meds_edit.json):
///   • Back → back
///   • Save plan → PUT /v1/program-data/bf/meds then toast “Plan saved” then back
/// API: —
class BfMedsEditScreen extends StatelessWidget {
  const BfMedsEditScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfMedsEditHeaderTitle),
      children: [
        TTitle(s.bfMedsEditBodyN0Text),
        TField(fieldKey: 'bf_meds_edit.medicine', label: s.bfMedsEditBodyN1Label, placeholder: s.bfMedsEditBodyN1Placeholder, kind: TFieldKind.select, bind: 'bf.meds.medicine', bindClass: TBindClass.plan),
        TField(fieldKey: 'bf_meds_edit.strength', label: s.bfMedsEditBodyN2Label, placeholder: s.bfMedsEditBodyN2Placeholder),
        TField(fieldKey: 'bf_meds_edit.when', label: s.bfMedsEditBodyN3Label, placeholder: s.bfMedsEditBodyN3Placeholder, kind: TFieldKind.select, bind: 'bf.meds.when', bindClass: TBindClass.plan),
        TToggleRow(fieldKey: 'bf_meds_edit.private_reminder', label: s.bfMedsEditBodyN4Label, sub: s.bfMedsEditBodyN4Sub, value: true, bind: 'bf.meds.private_reminder', bindClass: TBindClass.plan),
        TBody(s.bfMedsEditBodyN5Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfMedsEditFooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/bf/meds', screenId: 'bf_meds_edit', then: () => TNav.toast(context, s.bfMedsEditFooterN0ActionThenValue, then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
