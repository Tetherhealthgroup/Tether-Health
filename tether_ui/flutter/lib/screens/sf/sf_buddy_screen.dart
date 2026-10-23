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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfBuddyHeaderTitle, pill: s.sfBuddyHeaderPill),
      children: [
        TTitle(s.sfBuddyBodyN0Text),
        TBody(s.sfBuddyBodyN1Text, tone: TTextTone.muted),
        TField(fieldKey: 'sf_buddy.name', label: s.sfBuddyBodyN2Label, placeholder: s.sfBuddyBodyN2Placeholder),
        TChecklist(fieldKey: 'sf_buddy.buddy_can_see', items: [TCheckItem(s.sfBuddyBodyN3ItemsN0Label, value: 'A weekly “I hit my goal” message', done: true), TCheckItem(s.sfBuddyBodyN3ItemsN1Label, value: 'My minutes per day'), TCheckItem(s.sfBuddyBodyN3ItemsN2Label, value: 'Nothing automatic: I send each one', done: true)], label: s.sfBuddyBodyN3Label, bind: 'sf.buddy.can_see'),
        TBoundValues(keys: const ['sf.buddy.preview_message'], builder: (context, v) => TCard(variant: TCardVariant.mint, eyebrow: s.sfBuddyBodyN4Eyebrow, children: [TQuote(v.text('sf.buddy.preview_message', s.sfBuddyBodyN4ChildrenN0Text))])),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfBuddyFooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/program-data/sf/plan', screenId: 'sf_buddy', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.sfHome))), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.sfBuddyFooterN1Label, onTap: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.sfHome))),
      ],
    );
  }
}
