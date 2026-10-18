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
    return TScreen(
      header: THeader(title: 'Limits', pill: 'Step 3 of 3'),
      children: [
        TTitle('When should Unplug step in?'),
        TCard(children: [TSliderField(fieldKey: 'sf_unplug_limits.daily_minutes', label: 'Daily time in these apps', value: 60.0, min: 15.0, max: 240.0, minLabel: '15 min', maxLabel: '4 h', color: TColors.program('sf'), suffix: ' min'), TSliderField(fieldKey: 'sf_unplug_limits.daily_opens', label: 'Opens a day', value: 20.0, min: 5.0, max: 60.0, minLabel: '5', maxLabel: '60', color: TColors.program('sf')), TBody('On iPhone, opens are counted from pause screens shown, so the number is approximate.', tone: TTextTone.small)]),
        TRadioList(fieldKey: 'sf_unplug_limits.level', items: [TRadioItem('Notice only', sub: 'Count time, no pause screen'), TRadioItem('Pause screen', sub: 'A pause before the app opens'), TRadioItem('Pause and one small step', sub: 'A breath, a typed sentence or a quick sum first', badge: 'Suggested'), TRadioItem('Firm', sub: 'No “open anyway” until tomorrow')], selected: 2, label: 'When you reach a limit'),
        TChips(fieldKey: 'sf_unplug_limits.gate', options: ['One breath', 'Type a sentence', 'Quick sum'], selected: ['One breath'], multi: false, label: 'Small step'),
        TSegmented(fieldKey: 'sf_unplug_limits.overrides', options: ['0', '1', '3', '5'], selected: '3', label: '“Open anyway” per day'),
        TBody('Stricter limits apply now. Looser limits start tomorrow, so one hard moment doesn’t change your plan.', tone: TTextTone.small),
        TBody('Every pause screen has a Get support button. Tether, the phone dialer and emergency calling can never be chosen or paused.', tone: TTextTone.small),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Save limits', onPressed: () => TNav.submit(context, 'CALL device:unplug/setThresholds+applyShield', then: () => TNav.toast(context, 'Unplug is on', then: () => TNav.replace(context, Routes.sfUnplugHome))), arrow: true),
      ],
    );
  }
}
