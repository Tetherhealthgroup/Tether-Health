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
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.progressHeaderTitle, left: THeaderLeft.none, avatar: 'A', onAvatar: () => TNav.push(context, Routes.account)),
      tab: 'progress',
      children: [
        TSegmented(fieldKey: 'progress.value', options: ['7 days', '30 days', 'All'], labels: [s.progressBodyN0OptionsN0, s.progressBodyN0OptionsN1, s.progressBodyN0OptionsN2], selected: '7 days'),
        TBody(s.progressBodyN1Text, tone: TTextTone.small),
        TBarChart(values: [10.0, 7.0, 4.0, 3.0, 1.0, 1.0, 0.0], color: TColors.program('bf'), missing: [3], labels: [s.progressBodyN2LabelsN0, s.progressBodyN2LabelsN1, s.progressBodyN2LabelsN2, s.progressBodyN2LabelsN3, s.progressBodyN2LabelsN4, s.progressBodyN2LabelsN5, s.progressBodyN2LabelsN6], key: const ValueKey('a:body[2]'), title: s.progressBodyN2Title, caption: s.progressBodyN2Caption, tag: 'bf', onTap: () => TNav.push(context, Routes.bfProgress)),
        TBarChart(values: [190.0, 160.0, 150.0, 115.0, 130.0, 95.0, 85.0], color: TColors.program('sf'), target: 90.0, labels: [s.progressBodyN3LabelsN0, s.progressBodyN3LabelsN1, s.progressBodyN3LabelsN2, s.progressBodyN3LabelsN3, s.progressBodyN3LabelsN4, s.progressBodyN3LabelsN5, s.progressBodyN3LabelsN6], key: const ValueKey('a:body[3]'), title: s.progressBodyN3Title, caption: s.progressBodyN3Caption, tag: 'sf', onTap: () => TNav.push(context, Routes.sfWeek)),
        TCard(variant: TCardVariant.mint, eyebrow: s.progressBodyN4Eyebrow, title: s.progressBodyN4Title, text: s.progressBodyN4Text, cta: TButton(key: const ValueKey('a:body[4].cta[0]'), label: s.progressBodyN4CtaN0Label, onPressed: () => TNav.push(context, Routes.accountPrivacy), variant: TButtonVariant.secondary, small: true)),
      ],
    );
  }
}
