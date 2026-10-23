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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfReviewHeaderTitle, pill: s.bfReviewHeaderPill),
      children: [
        TTitle(s.bfReviewBodyN0Text),
        TBody(s.bfReviewBodyN1Text, tone: TTextTone.muted),
        TBoundValues(keys: const ['bf.review.approach', 'bf.review.quit_date', 'bf.review.top_reason', 'bf.review.support', 'bf.review.space'], builder: (context, v) => TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.bfReviewBodyN2RowsN0Label, sub: v.text('bf.review.approach', s.bfReviewBodyN2RowsN0Sub), onTap: () => TNav.push(context, Routes.bfPath)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.bfReviewBodyN2RowsN1Label, sub: v.text('bf.review.quit_date', s.bfReviewBodyN2RowsN1Sub), onTap: () => TNav.push(context, Routes.bfDate)), TListRow(key: const ValueKey('a:body[2].rows[2]'), label: s.bfReviewBodyN2RowsN2Label, sub: v.text('bf.review.top_reason', s.bfReviewBodyN2RowsN2Sub), onTap: () => TNav.push(context, Routes.bfQ3)), TListRow(key: const ValueKey('a:body[2].rows[3]'), label: s.bfReviewBodyN2RowsN3Label, sub: v.text('bf.review.support', s.bfReviewBodyN2RowsN3Sub), onTap: () => TNav.push(context, Routes.bfSupport)), TListRow(key: const ValueKey('a:body[2].rows[4]'), label: s.bfReviewBodyN2RowsN4Label, sub: v.text('bf.review.space', s.bfReviewBodyN2RowsN4Sub), onTap: () => TNav.push(context, Routes.bfSupport))])),
        TBody(s.bfReviewBodyN3Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfReviewFooterN0Label, onPressed: () => TNav.submit(context, 'PUT /v1/quit-plan', screenId: 'bf_review', then: () => TNav.replace(context, (TFlow.onboarding ? Routes.obSetup : Routes.bfHome))), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.bfReviewFooterN1Label, onTap: () => TNav.tab(context, Routes.plans)),
      ],
    );
  }
}
