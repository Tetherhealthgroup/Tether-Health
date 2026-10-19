// GENERATED from spec/screens/bf_review.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Review plan  ·  route `/p/bf/plan/review`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase plan
/// 
///
/// Actions (generated from spec/screens/bf_review.json):
///   • Back → back
///   • Quit approach → push → bf_path
///   • Quit date → push → bf_date
///   • Top reason → push → bf_q3
///   • Support → push → bf_support
///   • Space → push → bf_support
///   • Start my plan → PUT /v1/quit-plan then replace → bf_home (onboarding: ob_setup)
///   • Save and finish later → tab → plans
/// API: PUT /v1/quit-plan
class BfReviewScreen extends StatelessWidget {
  const BfReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Review your plan', pill: 'Ready'),
      children: [
        TTitle('Your plan is ready.'),
        TBody('Tap any item to edit.', tone: TTextTone.muted),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Quit approach', sub: 'Set a quit date', onTap: () => TNav.push(context, Routes.bfPath)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: 'Quit date', sub: 'Fri, Aug 28 · 7 days to prepare', onTap: () => TNav.push(context, Routes.bfDate)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: 'Top reason', sub: 'Protect my family', onTap: () => TNav.push(context, Routes.bfQ3)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: 'Support', sub: 'Jordan · evening before', onTap: () => TNav.push(context, Routes.bfSupport)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: 'Space', sub: '2 of 3 tasks done', onTap: () => TNav.push(context, Routes.bfSupport))]),
        TBody('Starting turns on your preparation tasks and reminders. Support messages always need your approval.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Start my plan', onPressed: () => TNav.submit(context, 'PUT /v1/quit-plan', screenId: 'bf_review', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.bfHome))), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: 'Save and finish later', onTap: () => TNav.tab(context, Routes.plans)),
      ],
    );
  }
}
