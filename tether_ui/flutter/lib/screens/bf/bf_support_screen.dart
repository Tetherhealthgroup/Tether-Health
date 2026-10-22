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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfSupportHeaderTitle, pill: s.bfSupportHeaderPill),
      children: [
        TTitle(s.bfSupportBodyN0Text),
        TListGroup(title: s.bfSupportBodyN1Title, rows: [TListRow(key: const ValueKey('a:body[1].rows[0]'), label: s.bfSupportBodyN1RowsN0Label, sub: s.bfSupportBodyN1RowsN0Sub, lead: TLead.avatar('J'), onTap: () => TNav.push(context, Routes.supportAddPerson)), TListRow(key: const ValueKey('a:body[1].rows[1]'), label: s.bfSupportBodyN1RowsN1Label, lead: TLead.icon('+'), onTap: () => TNav.push(context, Routes.supportAddPerson))]),
        TCard(eyebrow: s.bfSupportBodyN2Eyebrow, children: [TChecklist(items: [TCheckItem(s.bfSupportBodyN2ChildrenN0ItemsN0Label, value: 'Remove cigarettes, lighters, ashtrays', done: true), TCheckItem(s.bfSupportBodyN2ChildrenN0ItemsN1Label, value: 'Make home and car smoke-free', done: true), TCheckItem(s.bfSupportBodyN2ChildrenN0ItemsN2Label, value: 'Stock gum, water or snacks')])]),
        TToggleRow(fieldKey: 'bf_support.remind_me_to_discuss_quit_medici', label: s.bfSupportBodyN3Label, sub: s.bfSupportBodyN3Sub, value: true),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfSupportFooterN0Label, onPressed: () => TNav.push(context, Routes.bfReview), arrow: true),
      ],
    );
  }
}
