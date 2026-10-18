// GENERATED from spec/screens/progress.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Progress  ·  route `/progress`  ·  flow `tabs`  ·  kind `screen`
/// Default state · phase resources
/// 
///
/// Actions (generated from spec/screens/progress.json):
///   • Avatar · Account → push → account
///   • Cigarettes / day → push → bf_progress
///   • Social minutes / day → push → sf_week
///   • Manage → push → account_privacy
///   • Tab · Today → tab → today
///   • Tab · Plans → tab → plans
///   • Tab · Learn → tab → learn
///   • Tab · Support → tab → support
/// API: GET /v1/records/summary?range=7d
class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Progress', left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'progress',
      children: [
        TSegmented(fieldKey: 'progress.value', options: ['7 days', '30 days', 'All'], selected: '7 days'),
        TBody('Patterns, not grades. Missing check-ins are never counted as zero.', tone: TTextTone.small),
        TBarChart(values: [10.0, 7.0, 4.0, 3.0, 1.0, 1.0, 0.0], color: TColors.program('bf'), missing: [3], labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'], key: const ValueKey('a:body[2]'), title: 'Cigarettes / day', caption: 'Saved \$42.70 · avoided 61', tag: 'bf', onTap: () => TNav.push(context, Routes.bfProgress)),
        TBarChart(values: [190.0, 160.0, 150.0, 115.0, 130.0, 95.0, 85.0], color: TColors.program('sf'), target: 90.0, labels: ['M', 'T', 'W', 'T', 'F', 'S', 'S'], key: const ValueKey('a:body[3]'), title: 'Social minutes / day', caption: 'Goal 90 min · reclaimed 5h 40m', tag: 'sf', onTap: () => TNav.push(context, Routes.sfWeek)),
        TCard(variant: TCardVariant.mint, eyebrow: 'Connection we noticed', title: 'Late scrolling came before 3 of your 4 strongest cravings.', text: 'Shown because both programs are yours.', cta: TButton(key: const ValueKey('a:body[4].cta[0]'), label: 'Manage', onPressed: () => TNav.push(context, Routes.accountPrivacy), variant: TButtonVariant.secondary, small: true)),
      ],
    );
  }
}
