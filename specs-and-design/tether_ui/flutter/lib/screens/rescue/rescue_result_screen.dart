// GENERATED from spec/screens/rescue_result.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Recheck + result  ·  route `/rescue/result`  ·  flow `rescue`  ·  kind `screen`
/// Default state · phase rescue
/// 
///
/// Actions (generated from spec/screens/rescue_result.json):
///   • Close → close
///   • Still strong? Get more help → push → rescue_escalate
///   • Back to Today → POST /v1/records/rescues then reset → today
/// API: POST /v1/records/rescues
class RescueResultScreen extends StatelessWidget {
  const RescueResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.rescueResultHeaderTitle, left: THeaderLeft.close, pill: s.rescueResultHeaderPill),
      children: [
        TTitle(s.rescueResultBodyN0Text),
        TSliderField(fieldKey: 'rescue_result.how_strong_is_it_now', label: s.rescueResultBodyN1Label, value: 3.0, min: 0.0, max: 10.0, minLabel: '0', maxLabel: '10', color: TColors.coral),
        TBoundValues(keys: const ['rescue.rating_before', 'rescue.rating_now'], builder: (context, v) => TStatGrid(stats: [TStat(label: s.rescueResultBodyN2ItemsN0Label, value: v.text('rescue.rating_before', '8')), TStat(label: s.rescueResultBodyN2ItemsN1Label, value: v.text('rescue.rating_now', '3'), sub: s.rescueResultBodyN2ItemsN1Sub)])),
        TChips(fieldKey: 'rescue_result.did_it_help', options: ['Yes', 'A little', 'Not this time'], labels: [s.rescueResultBodyN3OptionsN0, s.rescueResultBodyN3OptionsN1, s.rescueResultBodyN3OptionsN2], selected: ['Yes'], multi: false, label: s.rescueResultBodyN3Label),
        TCard(variant: TCardVariant.mint, eyebrow: s.rescueResultBodyN4Eyebrow, title: s.rescueResultBodyN4Title),
        TLink(key: const ValueKey('a:body[5]'), label: s.rescueResultBodyN5Label, onTap: () => TNav.push(context, Routes.rescueEscalate)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.rescueResultFooterN0Label, onPressed: () => TNav.submit(context, 'POST /v1/records/rescues', screenId: 'rescue_result', then: () => TNav.reset(context, Routes.today)), arrow: true),
      ],
    );
  }
}
