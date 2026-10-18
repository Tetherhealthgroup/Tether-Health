// GENERATED from spec/screens/bf_support.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Support & preparation  ·  route `/p/bf/plan/support`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase plan
/// 
///
/// Actions (generated from spec/screens/bf_support.json):
///   • Back → back
///   • Jordan → push → support_add_person
///   • Add a supporter → push → support_add_person
///   • Review my plan → push → bf_review
/// API: —
class BfSupportScreen extends StatelessWidget {
  const BfSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Support', pill: 'Plan 3 of 3'),
      children: [
        TTitle('You don’t have to do this alone.'),
        TListGroup(title: 'Your support circle', rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: 'Jordan', sub: 'Friend · text message · evening before', lead: TLead.avatar('J'), onTap: () => TNav.push(context, Routes.supportAddPerson)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: 'Add a supporter', lead: TLead.icon('+'), onTap: () => TNav.push(context, Routes.supportAddPerson))]),
        TCard(eyebrow: 'Prepare your space · 2 of 3', children: [TChecklist(items: [TCheckItem('Remove cigarettes, lighters, ashtrays', done: true), TCheckItem('Make home and car smoke-free', done: true), TCheckItem('Stock gum, water or snacks')])]),
        TToggleRow(fieldKey: 'bf_support.remind_me_to_discuss_quit_medici', label: 'Remind me to discuss quit medicines with my care team', sub: 'Education only. The app never prescribes.', value: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Review my plan', onPressed: () => TNav.push(context, Routes.bfReview), arrow: true),
      ],
    );
  }
}
