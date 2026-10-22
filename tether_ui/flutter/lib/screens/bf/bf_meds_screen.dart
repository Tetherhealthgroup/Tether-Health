// GENERATED from spec/screens/bf_meds.json — edit the spec and re-run the generator,
// or move this file out of lib/screens/ to own it by hand.
import 'package:flutter/material.dart';

import '../../router/routes.dart';
import '../../ui/ui.dart';

/// Medication center  ·  route `/p/bf/meds`  ·  flow `bf`  ·  kind `screen`
/// Default state · program bf · phase resources
/// 
///
/// Actions (generated from spec/screens/bf_meds.json):
///   • Back → back
///   • Taken today → toast “Recorded: taken at 8:07 AM”
///   • Not today → toast “Recorded: not taken”
///   • Nicotine replacement → push → learn_lesson
///   • Prescription options → push → learn_lesson
///   • Side effect or worrying symptom? → push → support_message_care
///   • Add or update recorded plan → push → bf_meds_edit
/// API: —
class BfMedsScreen extends StatelessWidget {
  const BfMedsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = TStrings.of(context);
    return TScreen(
      header: THeader(title: s.bfMedsHeaderTitle),
      children: [
        TBanner(kind: TBannerKind.info, text: s.bfMedsBodyN0Text),
        TCard(eyebrow: s.bfMedsBodyN1Eyebrow, title: s.bfMedsBodyN1Title, text: s.bfMedsBodyN1Text, children: [TButtonRow(children: [TButton(key: const ValueKey('a:body[1].children[0].items[0]'), label: s.bfMedsBodyN1ChildrenN0ItemsN0Label, onPressed: () => TNav.toast(context, s.bfMedsBodyN1ChildrenN0ItemsN0ActionValue), small: true), TButton(key: const ValueKey('a:body[1].children[0].items[1]'), label: s.bfMedsBodyN1ChildrenN0ItemsN1Label, onPressed: () => TNav.toast(context, s.bfMedsBodyN1ChildrenN0ItemsN1ActionValue), variant: TButtonVariant.secondary, small: true)])]),
        TListGroup(title: s.bfMedsBodyN2Title, rows: [TListRow(key: const ValueKey('a:body[2].rows[0]'), label: s.bfMedsBodyN2RowsN0Label, sub: s.bfMedsBodyN2RowsN0Sub, onTap: () => TNav.push(context, Routes.learnLesson)), TListRow(key: const ValueKey('a:body[2].rows[1]'), label: s.bfMedsBodyN2RowsN1Label, sub: s.bfMedsBodyN2RowsN1Sub, onTap: () => TNav.push(context, Routes.learnLesson))]),
        TCard(variant: TCardVariant.warn, title: s.bfMedsBodyN3Title, text: s.bfMedsBodyN3Text),
        TCard(key: const ValueKey('a:body[4]'), variant: TCardVariant.urgent, title: s.bfMedsBodyN4Title, text: s.bfMedsBodyN4Text, onTap: () => TNav.push(context, Routes.supportMessageCare)),
      ],
      footer: [
        TButton(key: const ValueKey('a:footer[0]'), label: s.bfMedsFooterN0Label, onPressed: () => TNav.push(context, Routes.bfMedsEdit), variant: TButtonVariant.secondary),
      ],
    );
  }
}
