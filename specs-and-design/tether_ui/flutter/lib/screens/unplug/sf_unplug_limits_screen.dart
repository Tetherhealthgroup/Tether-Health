// GENERATED from spec/screens/sf_unplug_limits.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Limits & pause screen  ·  route `/p/sf/unplug/limits`  ·  flow `unplug`  ·  kind `screen`
/// Default state · program sf · phase plan
/// Copy needs clinical/legal review. Levels map to PlatformModuleConfig.tier (Notice 1, Pause 2, Pause + step 3, Firm 5 = no overrides). Small step maps to gate breath | commitment | puzzle. Device-only: nothing here is sent to Tether. Looser limits take effect the next day.
///
/// Actions (generated from spec/screens/sf_unplug_limits.json):
///   • Back → back
///   • Save limits → CALL device:unplug/setThresholds+applyShield then toast “Unplug is on” then replace → sf_unplug_home
/// API: —
class SfUnplugLimitsScreen extends StatelessWidget {
  const SfUnplugLimitsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugLimitsHeaderTitle, pill: s.sfUnplugLimitsHeaderPill),
      children: [
        TTitle(s.sfUnplugLimitsBodyN0Text),
        TCard(children: [TSliderField(fieldKey: 'sf_unplug_limits.daily_minutes', label: s.sfUnplugLimitsBodyN1ChildrenN0Label, value: 60.0, min: 15.0, max: 240.0, minLabel: s.sfUnplugLimitsBodyN1ChildrenN0MinLabel, maxLabel: s.sfUnplugLimitsBodyN1ChildrenN0MaxLabel, color: TColors.program('sf'), suffix: ' min'), TSliderField(fieldKey: 'sf_unplug_limits.daily_opens', label: s.sfUnplugLimitsBodyN1ChildrenN1Label, value: 20.0, min: 5.0, max: 60.0, minLabel: '5', maxLabel: '60', color: TColors.program('sf')), TBody(s.sfUnplugLimitsBodyN1ChildrenN2Text, tone: TTextTone.small)]),
        TRadioList(fieldKey: 'sf_unplug_limits.level', items: [TRadioItem(s.sfUnplugLimitsBodyN2ItemsN0Label, value: 'Notice only', sub: s.sfUnplugLimitsBodyN2ItemsN0Sub), TRadioItem(s.sfUnplugLimitsBodyN2ItemsN1Label, value: 'Pause screen', sub: s.sfUnplugLimitsBodyN2ItemsN1Sub), TRadioItem(s.sfUnplugLimitsBodyN2ItemsN2Label, value: 'Pause and one small step', sub: s.sfUnplugLimitsBodyN2ItemsN2Sub, badge: s.sfUnplugLimitsBodyN2ItemsN2Badge), TRadioItem(s.sfUnplugLimitsBodyN2ItemsN3Label, value: 'Firm', sub: s.sfUnplugLimitsBodyN2ItemsN3Sub)], selected: 2, label: s.sfUnplugLimitsBodyN2Label),
        TChips(fieldKey: 'sf_unplug_limits.gate', options: ['One breath', 'Type a sentence', 'Quick sum'], labels: [s.sfUnplugLimitsBodyN3OptionsN0, s.sfUnplugLimitsBodyN3OptionsN1, s.sfUnplugLimitsBodyN3OptionsN2], selected: ['One breath'], multi: false, label: s.sfUnplugLimitsBodyN3Label),
        TSegmented(fieldKey: 'sf_unplug_limits.overrides', options: ['0', '1', '3', '5'], selected: '3', label: s.sfUnplugLimitsBodyN4Label),
        TBody(s.sfUnplugLimitsBodyN5Text, tone: TTextTone.small),
        TBody(s.sfUnplugLimitsBodyN6Text, tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugLimitsFooterN0Label, onPressed: () => TNav.submit(context, 'CALL device:unplug/setThresholds+applyShield', screenId: 'sf_unplug_limits', then: () => TNav.toast(context, s.sfUnplugLimitsFooterN0ActionThenValue, then: () => TNav.replace(context, Routes.sfUnplugHome))), arrow: true),
      ],
    );
  }
}
