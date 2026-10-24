// GENERATED from spec/screens/sf_unplug_intro.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Unplug intro  ·  route `/p/sf/unplug`  ·  flow `unplug`  ·  kind `screen`
/// Default state · program sf · phase plan
/// Copy needs clinical/legal review. Shown before anything is switched on, so nobody later reads a number that does not exist. Pause 60 stays an intent check; Unplug is the optional lock.
///
/// Actions (generated from spec/screens/sf_unplug_intro.json):
///   • Back → back
///   • Set up Unplug → branch: Platform → iPhone: push → sf_unplug_auth | Android: push → sf_unplug_auth_android
///   • Not now → back
/// API: —
class SfUnplugIntroScreen extends StatelessWidget {
  const SfUnplugIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: 'Unplug', pill: s.sfUnplugIntroHeaderPill),
      children: [
        TProgramTag(program: 'sf', extra: 'Unplug'),
        TTitle(s.sfUnplugIntroBodyN1Text, size: TTitleSize.l),
        TBody(s.sfUnplugIntroBodyN2Text, tone: TTextTone.muted),
        TKeyValue(rows: [(s.sfUnplugIntroBodyN3RowsN0N0, s.sfUnplugIntroBodyN3RowsN0N1), (s.sfUnplugIntroBodyN3RowsN1N0, s.sfUnplugIntroBodyN3RowsN1N1), (s.sfUnplugIntroBodyN3RowsN2N0, s.sfUnplugIntroBodyN3RowsN2N1), (s.sfUnplugIntroBodyN3RowsN3N0, s.sfUnplugIntroBodyN3RowsN3N1), (s.sfUnplugIntroBodyN3RowsN4N0, s.sfUnplugIntroBodyN3RowsN4N1)]),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugIntroFooterN0Label, onPressed: () => TNav.branch(context, 'Platform', <String, VoidCallback>{'iPhone': () => TNav.push(context, Routes.sfUnplugAuth), 'Android': () => TNav.push(context, Routes.sfUnplugAuthAndroid)}, device: const TBranchRef('unplug.intro.platform', TAsk.platform, 'sf_unplug_intro'), when: const <TAnswer, String>{TAnswer.ios: 'iPhone', TAnswer.android: 'Android'}), arrow: true),
        TButton(key: const ValueKey('a:footer[1]'), label: s.sfUnplugIntroFooterN1Label, onPressed: () => TNav.back(context), variant: TButtonVariant.secondary),
      ],
    );
  }
}
