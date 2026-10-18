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
    return TScreen(
      header: THeader(title: 'Rescue done', left: THeaderLeft.close, pill: 'Saved'),
      children: [
        TTitle('This craving eased.'),
        TSliderField(fieldKey: 'rescue_result.how_strong_is_it_now', label: 'How strong is it now?', value: 3.0, min: 0.0, max: 10.0, minLabel: '0', maxLabel: '10', color: TColors.coral),
        TStatGrid(stats: [TStat(label: 'Before', value: '8'), TStat(label: 'Now', value: '3', sub: 'Your rating, not a diagnosis')]),
        TChips(fieldKey: 'rescue_result.did_it_help', options: ['Yes', 'A little', 'Not this time'], selected: ['Yes'], multi: false, label: 'Did it help?'),
        TCard(variant: TCardVariant.mint, eyebrow: 'Next 10 minutes', title: 'Stay somewhere smoke-free and sip water.'),
        TLink(key: const ValueKey('a:body[5]'), label: 'Still strong? Get more help', onTap: () => TNav.push(context, Routes.rescueEscalate)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Back to Today', onPressed: () => TNav.submit(context, 'POST /v1/records/rescues', then: () => TNav.reset(context, Routes.today)), arrow: true),
      ],
    );
  }
}
