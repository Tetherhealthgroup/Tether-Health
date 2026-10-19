// GENERATED from spec/screens/sf_buddy.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Accountability buddy  ·  route `/p/sf/plan/buddy`  ·  flow `sf`  ·  kind `screen`
/// Default state · program sf · phase plan
/// 
///
/// Actions (generated from spec/screens/sf_buddy.json):
///   • Back → back
///   • Save and finish → PUT /v1/program-data/sf/plan then replace → sf_home (onboarding: ob_setup)
///   • Skip for now → replace → sf_home (onboarding: ob_setup)
/// API: —
class SfBuddyScreen extends StatelessWidget {
  const SfBuddyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Buddy', pill: 'Optional'),
      children: [
        TTitle('Want someone in your corner?'),
        TBody('Your buddy only sees what you choose to send.', tone: TTextTone.muted),
        TField(fieldKey: 'sf_buddy.name', label: 'Name', placeholder: 'Sam'),
        TChecklist(fieldKey: 'sf_buddy.buddy_can_see', items: [TCheckItem('A weekly “I hit my goal” message', done: true), TCheckItem('My minutes per day'), TCheckItem('Nothing automatic: I send each one', done: true)], label: 'They can see'),
        TCard(variant: TCardVariant.mint, eyebrow: 'Preview', children: [TQuote('Phone-free nights this week: 5. Thanks for cheering me on!')]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save and finish', onPressed: () => TNav.submit(context, 'PUT /v1/program-data/sf/plan', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.sfHome))), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Skip for now', onTap: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.sfHome))),
      ],
    );
  }
}
