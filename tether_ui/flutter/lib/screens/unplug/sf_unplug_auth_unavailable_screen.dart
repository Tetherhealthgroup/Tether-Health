// GENERATED from spec/screens/sf_unplug_auth_unavailable.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../ui/ui.dart';

/// Screen Time unavailable  ·  route `/p/sf/unplug/permission?state=unavailable`  ·  flow `unplug`  ·  kind `screen`
/// State: unavailable of sf_unplug_auth · program sf · phase plan
/// Copy needs clinical/legal review.
///
/// Actions (generated from spec/screens/sf_unplug_auth_unavailable.json):
///   • Back → back
///   • Back to ScrollFree → back
/// API: —
class SfUnplugAuthUnavailableScreen extends StatelessWidget {
  const SfUnplugAuthUnavailableScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return TScreen(
      header: THeader(title: 'Unplug', pill: 'Optional'),
      children: [
        TBanner(kind: TBannerKind.info, text: 'Screen Time isn’t available on this phone.'),
        TTitle('Unplug can’t run here.'),
        TBody('This can happen when Screen Time is managed by an organization or limited by a parent. ScrollFree still works without Unplug.', tone: TTextTone.muted),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: 'Back to ScrollFree', onPressed: () => TNav.back(context), arrow: true),
      ],
    );
  }
}
