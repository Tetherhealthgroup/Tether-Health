// GENERATED from spec/screens/sd_fell.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// I fell  ·  route `/p/sd/fell`  ·  flow `sd`  ·  kind `fullscreen`
/// Default state · program sd · phase rescue
/// 
///
/// Actions (generated from spec/screens/sd_fell.json):
///   • Close → close
///   • I hit my head or can’t get up · Call 911 → call 911
///   • Call Rosa → call (555) 010-2244
///   • How to get up safely → push → learn_lesson
///   • I’m okay, log this fall → POST /v1/program-data/sd/falls then toast “Fall logged. Added to your visit list.” then replace → sd_home
/// API: —
class SdFellScreen extends StatelessWidget {
  const SdFellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'I fell', left: THeaderLeft.close),
      children: [
        TTitle('Are you hurt?'),
        TButton(key: const ValueKey('a:body[1]'), label: 'I hit my head or can’t get up · Call 911', onPressed: () => TNav.call(context, '911', label: '911'), variant: TButtonVariant.danger),
        TListGroup(rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: 'Call Rosa', sub: 'Caregiver', lead: TLead.avatar('R'), onTap: () => TNav.call(context, '(555) 010-2244', label: 'Call Rosa'))]),
        TCard(key: const ValueKey('a:body[3]'), variant: TCardVariant.mint, title: 'How to get up safely', text: 'Roll to your side, crawl to a sturdy chair, kneel, then rise slowly.', onTap: () => TNav.push(context, Routes.learnLesson)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'I’m okay, log this fall', onPressed: () => TNav.submit(context, 'POST /v1/program-data/sd/falls', screenId: 'sd_fell', then: () => TNav.toast(context, 'Fall logged. Added to your visit list.', then: () => TNav.replace(context, Routes.sdHome))), variant: TButtonVariant.secondary),
      ],
    );
  }
}
