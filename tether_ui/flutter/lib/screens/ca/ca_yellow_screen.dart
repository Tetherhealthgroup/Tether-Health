// GENERATED from spec/screens/ca_yellow.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Yellow zone  ·  route `/p/ca/zone/yellow`  ·  flow `ca`  ·  kind `screen`
/// Default state · program ca · phase rescue
/// 
///
/// Actions (generated from spec/screens/ca_yellow.json):
///   • Back → back
///   • Getting worse or can’t speak in full sentences? → replace → ca_red
///   • Remind me in 20 min → toast “Reminder set for 20 minutes” then replace → ca_home
///   • Message care team → push → support_message_care
/// API: —
class CaYellowScreen extends StatelessWidget {
  const CaYellowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.caYellowHeaderTitle, pill: s.caYellowHeaderPill),
      children: [
        TBoundValues(keys: const ['ca.plan_entered_line'], builder: (context, v) => TCard(variant: TCardVariant.warn, title: s.caYellowBodyN0Title, text: v.text('ca.plan_entered_line', s.caYellowBodyN0Text))),
        TCard(children: [TChecklist(items: [TCheckItem(s.caYellowBodyN1ChildrenN0ItemsN0Label, value: 'Reliever inhaler · 2–4 puffs', sub: s.caYellowBodyN1ChildrenN0ItemsN0Sub, done: true), TCheckItem(s.caYellowBodyN1ChildrenN0ItemsN1Label, value: 'Re-check in 20 minutes', sub: s.caYellowBodyN1ChildrenN0ItemsN1Sub), TCheckItem(s.caYellowBodyN1ChildrenN0ItemsN2Label, value: 'Tell your care team if no better', sub: s.caYellowBodyN1ChildrenN0ItemsN2Sub)])]),
        TCard(key: const ValueKey('a:body[2]'), variant: TCardVariant.urgent, title: s.caYellowBodyN2Title, text: s.caYellowBodyN2Text, onTap: () => TNav.replace(context, Routes.caRed)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.caYellowFooterN0Label, onPressed: () => TNav.toast(context, s.caYellowFooterN0ActionValue, then: () => TNav.replace(context, Routes.caHome)), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.caYellowFooterN1Label, onPressed: () => TNav.push(context, Routes.supportMessageCare), variant: TButtonVariant.secondary),
      ],
    );
  }
}
