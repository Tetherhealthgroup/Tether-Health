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
    return TScreen(
      header: THeader(title: 'Yellow zone', pill: 'Your plan'),
      children: [
        TCard(variant: TCardVariant.warn, title: 'Follow your yellow-zone steps', text: 'From the plan you entered on Sep 3'),
        TCard(children: [TChecklist(items: [TCheckItem('Reliever inhaler · 2–4 puffs', sub: 'As written in your plan', done: true), TCheckItem('Re-check in 20 minutes', sub: 'We’ll remind you'), TCheckItem('Tell your care team if no better', sub: 'As your plan directs')])]),
        TCard(key: const ValueKey('a:body[2]'), variant: TCardVariant.urgent, title: 'Getting worse or can’t speak in full sentences?', text: 'Go to your red-zone plan', onTap: () => TNav.replace(context, Routes.caRed)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Remind me in 20 min', onPressed: () => TNav.toast(context, 'Reminder set for 20 minutes', then: () => TNav.replace(context, Routes.caHome)), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Message care team', onPressed: () => TNav.push(context, Routes.supportMessageCare), variant: TButtonVariant.secondary),
      ],
    );
  }
}
