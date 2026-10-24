// GENERATED from spec/screens/ob_third.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Third program sheet  ·  route `/onboarding/focus/third`  ·  flow `onboarding`  ·  kind `sheet`
/// Default state · phase welcome
/// 
///
/// Actions (generated from spec/screens/ob_third.json):
///   • Continue → toast “Heartwise added as Learn only” then close
///   • Cancel → close
/// API: —
class ObThirdScreen extends StatelessWidget {
  const ObThirdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TSheet(
      children: [
        TEyebrow(s.obThirdBodyN0Text),
        TTitle(s.obThirdBodyN1Text),
        TRadioList(fieldKey: 'ob_third.value', items: [TRadioItem(s.obThirdBodyN2ItemsN0Label, value: 'Learn only for now', sub: s.obThirdBodyN2ItemsN0Sub, badge: s.obThirdBodyN2ItemsN0Badge), TRadioItem(s.obThirdBodyN2ItemsN1Label, value: 'Swap with ScrollFree', sub: s.obThirdBodyN2ItemsN1Sub), TRadioItem(s.obThirdBodyN2ItemsN2Label, value: 'Swap with BreatheFree', sub: s.obThirdBodyN2ItemsN2Sub)], selected: 0),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.obThirdFooterN0Label, onPressed: () => TNav.toast(context, s.obThirdFooterN0ActionValue, then: () => TNav.close(context)), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.obThirdFooterN1Label, onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
