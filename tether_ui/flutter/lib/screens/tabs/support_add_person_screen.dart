// GENERATED from spec/screens/support_add_person.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Add a supporter  ·  route `/support/people/new`  ·  flow `tabs`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/support_add_person.json):
///   • Back → back
///   • Save supporter → decide sup.programs: Anything selected? → Chosen: POST /v1/care/supporters then toast “Jordan added” then back | Nothing chosen: toast “Select at least one program.”
/// API: —
class SupportAddPersonScreen extends StatelessWidget {
  const SupportAddPersonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.supportAddPersonHeaderTitle),
      children: [
        TTitle(s.supportAddPersonBodyN0Text),
        TField(fieldKey: 'support_add_person.name', label: s.supportAddPersonBodyN1Label, placeholder: s.supportAddPersonBodyN1Placeholder),
        TField(fieldKey: 'support_add_person.phone', label: s.supportAddPersonBodyN2Label, placeholder: '(555) 010-4421', kind: TFieldKind.phone),
        TChips(fieldKey: 'support_add_person.which_programs', options: ['BreatheFree', 'ScrollFree'], label: s.supportAddPersonBodyN3Label),
        TField(fieldKey: 'support_add_person.help_phrase', label: s.supportAddPersonBodyN4Label, placeholder: s.supportAddPersonBodyN4Placeholder, kind: TFieldKind.multiline),
        TBody(s.supportAddPersonBodyN5Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.supportAddPersonFooterN0Label, onPressed: () => TNav.branch(context, 'Anything selected?', <String, VoidCallback>{'Chosen': () => TNav.submit(context, 'POST /v1/care/supporters', screenId: 'support_add_person', then: () => TNav.toast(context, s.supportAddPersonFooterN0ActionCasesN0ActionThenValue, then: () => TNav.back(context))), 'Nothing chosen': () => TNav.toast(context, s.supportAddPersonFooterN0ActionCasesN1ActionValue)}, decide: 'sup.programs'), arrow: true),
      ],
    );
  }
}
