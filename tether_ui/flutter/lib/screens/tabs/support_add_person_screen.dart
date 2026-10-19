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
///   • Save supporter → POST /v1/care/supporters then toast “Jordan added” then back
/// API: —
class SupportAddPersonScreen extends StatelessWidget {
  const SupportAddPersonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Add a supporter'),
      children: [
        TTitle('Who can you count on?'),
        TField(fieldKey: 'support_add_person.name', label: 'Name', placeholder: 'Jordan'),
        TField(fieldKey: 'support_add_person.phone', label: 'Phone', placeholder: '(555) 010-4421', kind: TFieldKind.phone),
        TChips(fieldKey: 'support_add_person.which_programs', options: ['BreatheFree', 'ScrollFree'], selected: ['BreatheFree'], label: 'Which programs?'),
        TField(fieldKey: 'support_add_person.help_phrase', label: 'Help phrase', placeholder: 'Can you stay with me for the next 10 minutes?', kind: TFieldKind.multiline),
        TBody('Nothing is sent until you preview and tap Send.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save supporter', onPressed: () => TNav.submit(context, 'POST /v1/care/supporters', screenId: 'support_add_person', then: () => TNav.toast(context, 'Jordan added', then: () => TNav.back(context))), arrow: true),
      ],
    );
  }
}
