// GENERATED from spec/screens/sf_unplug_gate_commit.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Small step: type a sentence  ·  route `/p/sf/unplug/step?state=sentence`  ·  flow `unplug`  ·  kind `fullscreen`
/// State: typed sentence of sf_unplug_gate · program sf · phase rescue
/// Copy needs clinical/legal review. Open it works only after the sentence is typed in full (rule sf.unplug.sentence).
///
/// Actions (generated from spec/screens/sf_unplug_gate_commit.json):
///   • Close → close
///   • Get support → sheet → rescue_pick
///   • Keep it closed → toast “Nice. The app stays closed.” then reset → sf_home
///   • Open it for 10 minutes → decide sf.unplug.sentence: Small step done? → Step done: toast “Open for 10 minutes. The pause screen comes back after.” then reset → sf_home | Step not done: toast “Type the whole sentence first.”
/// API: —
class SfUnplugGateCommitScreen extends StatelessWidget {
  const SfUnplugGateCommitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.sfUnplugGateCommitHeaderTitle, left: THeaderLeft.close, pill: 'Unplug'),
      children: [
        TTitle(s.sfUnplugGateCommitBodyN0Text, size: TTitleSize.l),
        TBody(s.sfUnplugGateCommitBodyN1Text),
        TField(fieldKey: 'sf_unplug_gate_commit.sentence', label: s.sfUnplugGateCommitBodyN2Label, placeholder: s.sfUnplugGateCommitBodyN2Placeholder),
        TCard(variant: TCardVariant.coral, title: s.sfUnplugGateCommitBodyN3Title, text: s.sfUnplugGateCommitBodyN3Text, cta: TButton(key: const ValueKey('a:body[3].cta[0]'), label: s.sfUnplugGateCommitBodyN3CtaN0Label, onPressed: () => TNav.sheet(context, Routes.rescuePick), variant: TButtonVariant.rescue, small: true)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.sfUnplugGateCommitFooterN0Label, onPressed: () => TNav.toast(context, s.sfUnplugGateCommitFooterN0ActionValue, then: () => TNav.reset(context, Routes.sfHome)), arrow: true),
        TLink(key: const ValueKey('a:footer[1]'), label: s.sfUnplugGateCommitFooterN1Label, onTap: () => TNav.branch(context, 'Small step done?', <String, VoidCallback>{'Step done': () => TNav.toast(context, s.sfUnplugGateCommitFooterN1ActionCasesN0ActionValue, then: () => TNav.reset(context, Routes.sfHome)), 'Step not done': () => TNav.toast(context, s.sfUnplugGateCommitFooterN1ActionCasesN1ActionValue)}, decide: 'sf.unplug.sentence')),
      ],
    );
  }
}
