// GENERATED from spec/screens/sf_unplug_off.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Turn off Unplug  ·  route `/p/sf/unplug/off`  ·  flow `unplug`  ·  kind `sheet`
/// Default state · program sf · phase account
/// Copy needs clinical/legal review. Unplug only: liftShield + purgeLocalData(0). With Screen Time: also revokes the ScrollFree screen_time consent (then the same purge).
///
/// Actions (generated from spec/screens/sf_unplug_off.json):
///   • Turn off → decide choice:sf_unplug_off.scope: Chosen option → Unplug only: CALL device:unplug/liftShield+purgeLocalData then toast “Unplug is off” then reset → sf_home | Unplug and Screen Time: PATCH /v1/enrolments/consents then toast “Unplug and Screen Time are off” then reset → sf_home
///   • Cancel → close
/// API: —
class SfUnplugOffScreen extends StatelessWidget {
  const SfUnplugOffScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TSheet(
      children: [
        TTitle('Turn off Unplug?'),
        TBody('Paused apps open normally again. Your ScrollFree goal, check-ins and Pause 60 stay.', tone: TTextTone.muted),
        TRadioList(fieldKey: 'sf_unplug_off.scope', items: [TRadioItem('Unplug only', sub: 'Removes app choices, limits and session history from this phone', badge: 'Default'), TRadioItem('Unplug and Screen Time access', sub: 'ScrollFree goes back to your own estimates')], selected: 0, bind: 'sf.unplug_off.scope'),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Turn off', onPressed: () => TNav.branch(context, 'Chosen option', <String, VoidCallback>{'Unplug only': () => TNav.submit(context, 'CALL device:unplug/liftShield+purgeLocalData', screenId: 'sf_unplug_off', then: () => TNav.toast(context, 'Unplug is off', then: () => TNav.reset(context, Routes.sfHome))), 'Unplug and Screen Time': () => TNav.submit(context, 'PATCH /v1/enrolments/consents', screenId: 'sf_unplug_off', then: () => TNav.toast(context, 'Unplug and Screen Time are off', then: () => TNav.reset(context, Routes.sfHome)))}, decide: 'choice:sf_unplug_off.scope'), variant: TButtonVariant.danger),
        TButton(key: const ValueKey('a:footer[1]'), label: 'Cancel', onPressed: () => TNav.close(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
